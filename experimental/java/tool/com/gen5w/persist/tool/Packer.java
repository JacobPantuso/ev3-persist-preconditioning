package com.gen5w.persist.tool;

import java.io.BufferedOutputStream;
import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.math.BigInteger;
import java.security.KeyPair;
import java.security.KeyPairGenerator;
import java.security.MessageDigest;
import java.util.ArrayList;
import java.util.Enumeration;
import java.util.List;
import java.util.zip.CRC32;
import java.util.zip.ZipEntry;
import java.util.zip.ZipFile;
import java.util.zip.ZipOutputStream;

/**
 * Builds the patched APK: every resource from the stock APK, the new classes.dex, and a fresh v1 signature
 * from a throwaway key made on the spot. The stock signature is dropped because it no longer matches.
 */
final class Packer {
    private static final String CN = "gen5w";

    private Packer() {
    }

    static void run(File stockApk, File dexFile, File outApk) throws Exception {
        KeyPairGenerator kpg = KeyPairGenerator.getInstance("RSA");
        kpg.initialize(2048);
        KeyPair kp = kpg.generateKeyPair();
        BigInteger serial = Der.randomSerial();
        byte[] cert = Der.selfSignedCert(kp, CN, serial);

        List<String> names = new ArrayList<String>();
        List<byte[]> sections = new ArrayList<byte[]>();

        ZipFile zf = new ZipFile(stockApk);
        ZipOutputStream zos = new ZipOutputStream(new BufferedOutputStream(new FileOutputStream(outApk), 1 << 16));
        try {
            zos.setLevel(6);
            Enumeration<? extends ZipEntry> en = zf.entries();
            while (en.hasMoreElements()) {
                ZipEntry e = en.nextElement();
                String n = e.getName();
                if (n.startsWith("META-INF/") || n.equals("classes.dex")) {
                    continue;
                }
                if (e.isDirectory()) {
                    ZipEntry d = new ZipEntry(n);
                    zos.putNextEntry(d);
                    zos.closeEntry();
                    continue;
                }
                byte[] sha1 = copyEntry(zf, e, zos);
                names.add(n);
                sections.add(section(n, sha1));
            }

            byte[] dex = readAll(dexFile);
            ZipEntry de = new ZipEntry("classes.dex");
            zos.putNextEntry(de);
            zos.write(dex, 0, dex.length);
            zos.closeEntry();
            names.add("classes.dex");
            sections.add(section("classes.dex", Hashing.sha1(dex)));

            ByteArrayOutputStream mf = new ByteArrayOutputStream();
            write(mf, "Manifest-Version: 1.0\r\nCreated-By: " + CN + "\r\n\r\n");
            for (byte[] s : sections) {
                mf.write(s, 0, s.length);
            }
            byte[] manifest = mf.toByteArray();

            ByteArrayOutputStream sf = new ByteArrayOutputStream();
            write(sf, "Signature-Version: 1.0\r\nCreated-By: " + CN + "\r\n");
            header(sf, "SHA1-Digest-Manifest", B64.encode(Hashing.sha1(manifest)));
            write(sf, "\r\n");
            for (int i = 0; i < names.size(); i++) {
                header(sf, "Name", names.get(i));
                header(sf, "SHA1-Digest", B64.encode(Hashing.sha1(sections.get(i))));
                write(sf, "\r\n");
            }
            byte[] sfBytes = sf.toByteArray();
            byte[] block = Der.signatureBlock(kp, cert, serial, CN, sfBytes);

            put(zos, "META-INF/MANIFEST.MF", manifest);
            put(zos, "META-INF/CERT.SF", sfBytes);
            put(zos, "META-INF/CERT.RSA", block);
        } finally {
            zos.close();
            zf.close();
        }
    }

    /** One manifest section: the name and the SHA-1 of the entry's bytes, with the 72-byte line limit. */
    private static byte[] section(String name, byte[] sha1) throws IOException {
        ByteArrayOutputStream b = new ByteArrayOutputStream();
        header(b, "Name", name);
        header(b, "SHA1-Digest", B64.encode(sha1));
        write(b, "\r\n");
        return b.toByteArray();
    }

    /** A "Key: value" header line, wrapped so no line is longer than 72 bytes including the CRLF. */
    static void header(ByteArrayOutputStream out, String key, String value) throws IOException {
        byte[] line = (key + ": " + value).getBytes("UTF-8");
        int pos = 0;
        boolean first = true;
        while (pos < line.length) {
            int max = first ? 70 : 69;
            int len = Math.min(max, line.length - pos);
            if (!first) {
                out.write(' ');
            }
            out.write(line, pos, len);
            out.write('\r');
            out.write('\n');
            pos += len;
            first = false;
        }
    }

    private static void write(ByteArrayOutputStream out, String s) throws IOException {
        byte[] b = s.getBytes("UTF-8");
        out.write(b, 0, b.length);
    }

    private static void put(ZipOutputStream zos, String name, byte[] data) throws IOException {
        zos.putNextEntry(new ZipEntry(name));
        zos.write(data, 0, data.length);
        zos.closeEntry();
    }

    /** Copies one entry, keeping its storage method (resources.arsc has to stay uncompressed), returns its SHA-1. */
    private static byte[] copyEntry(ZipFile zf, ZipEntry e, ZipOutputStream zos) throws Exception {
        MessageDigest sha1 = MessageDigest.getInstance("SHA-1");
        ZipEntry out = new ZipEntry(e.getName());
        if (e.getTime() != -1) {
            out.setTime(e.getTime());
        }
        byte[] buf = new byte[1 << 16];
        if (e.getMethod() == ZipEntry.STORED) {
            CRC32 crc = new CRC32();
            long size = 0;
            InputStream in = zf.getInputStream(e);
            try {
                int n;
                while ((n = in.read(buf)) > 0) {
                    crc.update(buf, 0, n);
                    size += n;
                }
            } finally {
                in.close();
            }
            out.setMethod(ZipEntry.STORED);
            out.setSize(size);
            out.setCompressedSize(size);
            out.setCrc(crc.getValue());
        } else {
            out.setMethod(ZipEntry.DEFLATED);
        }
        zos.putNextEntry(out);
        InputStream in = zf.getInputStream(e);
        try {
            int n;
            while ((n = in.read(buf)) > 0) {
                sha1.update(buf, 0, n);
                zos.write(buf, 0, n);
            }
        } finally {
            in.close();
        }
        zos.closeEntry();
        return sha1.digest();
    }

    static byte[] readAll(File f) throws IOException {
        InputStream in = new FileInputStream(f);
        try {
            ByteArrayOutputStream bo = new ByteArrayOutputStream();
            byte[] buf = new byte[1 << 16];
            int n;
            while ((n = in.read(buf)) > 0) {
                bo.write(buf, 0, n);
            }
            return bo.toByteArray();
        } finally {
            in.close();
        }
    }

    static void copy(InputStream in, OutputStream out) throws IOException {
        byte[] buf = new byte[1 << 16];
        int n;
        while ((n = in.read(buf)) > 0) {
            out.write(buf, 0, n);
        }
    }
}
