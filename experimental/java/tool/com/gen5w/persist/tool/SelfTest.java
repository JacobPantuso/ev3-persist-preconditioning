package com.gen5w.persist.tool;

import java.io.ByteArrayInputStream;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.OutputStream;
import java.io.PrintStream;
import java.util.zip.CRC32;
import java.util.zip.ZipEntry;
import java.util.zip.ZipOutputStream;

/**
 * Runs the whole pipeline on tiny sample data, in a scratch folder, without touching the real app.
 * The install script runs this first (after the smali half's own self-test): if the head unit cannot run
 * the tool, nothing is changed.
 */
final class SelfTest {
    private SelfTest() {
    }

    static int run(File work, PrintStream out) throws Exception {
        out.println("selftest: vm=" + System.getProperty("java.vm.name") + " " + System.getProperty("java.vm.version")
                + " arch=" + System.getProperty("os.arch") + " maxMemory=" + (Runtime.getRuntime().maxMemory() >> 20) + "MB");
        if (!work.exists() && !work.mkdirs()) {
            throw new IOException("cannot create " + work);
        }

        // 1. hashing and base64
        String md5 = Hashing.hex(Hashing.digest("MD5", new ByteArrayInputStream("abc".getBytes("UTF-8"))));
        if (!md5.equals("900150983cd24fb0d6963f7d28e17f72")) {
            out.println("selftest: FAIL md5 " + md5);
            return 1;
        }
        if (!B64.encode("foobar".getBytes("UTF-8")).equals("Zm9vYmFy")) {
            out.println("selftest: FAIL base64");
            return 1;
        }
        out.println("selftest: hashing ok");

        // 2. the smali half has already assembled a tiny dex for us
        File dex = new File(work, "selftest.dex");
        if (!dex.isFile()) {
            out.println("selftest: FAIL no " + dex + " (run AsmTool selftest first)");
            return 1;
        }

        // 3. pack a tiny stock APK with the new dex, sign it, and verify the signature and the dex
        File stock = new File(work, "stock.apk");
        makeStock(stock);
        File apk = new File(work, "out.apk");
        Packer.run(stock, dex, apk);
        out.println("selftest: packed " + apk.length() + " bytes (key generated on this device)");
        int rc = Verify.run(apk, out);
        if (rc != 0) {
            out.println("selftest: FAIL verify");
            return rc;
        }
        out.println("SELFTEST OK");
        return 0;
    }

    /** A small zip shaped like an APK: compressed and stored entries, plus an old signature that must be dropped. */
    private static void makeStock(File f) throws IOException {
        ZipOutputStream z = new ZipOutputStream(new FileOutputStream(f));
        try {
            put(z, "AndroidManifest.xml", "manifest bytes".getBytes("UTF-8"), false);
            put(z, "resources.arsc", "table bytes for the stored entry".getBytes("UTF-8"), true);
            put(z, "assets/readme.txt", "a longer asset entry, repeated. a longer asset entry, repeated.".getBytes("UTF-8"), false);
            put(z, "META-INF/OLD.SF", "stale signature".getBytes("UTF-8"), false);
        } finally {
            z.close();
        }
    }

    private static void put(ZipOutputStream z, String name, byte[] data, boolean stored) throws IOException {
        ZipEntry e = new ZipEntry(name);
        if (stored) {
            CRC32 crc = new CRC32();
            crc.update(data, 0, data.length);
            e.setMethod(ZipEntry.STORED);
            e.setSize(data.length);
            e.setCompressedSize(data.length);
            e.setCrc(crc.getValue());
        }
        z.putNextEntry(e);
        OutputStream o = z;
        o.write(data, 0, data.length);
        z.closeEntry();
    }
}
