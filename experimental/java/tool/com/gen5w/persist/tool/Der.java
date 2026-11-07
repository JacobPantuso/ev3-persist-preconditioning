package com.gen5w.persist.tool;

import java.io.ByteArrayOutputStream;
import java.math.BigInteger;
import java.security.GeneralSecurityException;
import java.security.KeyPair;
import java.security.Signature;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Random;
import java.util.StringTokenizer;
import java.util.TimeZone;

/**
 * Minimal DER writer: just enough to make a self-signed certificate and a JAR signature block (PKCS#7)
 * on a head unit that has no keytool or jarsigner. Only java.security / java.math are needed.
 */
final class Der {
    static final String SHA1_WITH_RSA = "1.2.840.113549.1.1.5";
    static final String RSA = "1.2.840.113549.1.1.1";
    static final String SHA1 = "1.3.14.3.2.26";
    static final String DATA = "1.2.840.113549.1.7.1";
    static final String SIGNED_DATA = "1.2.840.113549.1.7.2";
    static final String COMMON_NAME = "2.5.4.3";

    private Der() {
    }

    static byte[] tlv(int tag, byte[]... parts) {
        ByteArrayOutputStream body = new ByteArrayOutputStream();
        for (byte[] p : parts) {
            body.write(p, 0, p.length);
        }
        byte[] b = body.toByteArray();
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        out.write(tag);
        if (b.length < 0x80) {
            out.write(b.length);
        } else if (b.length < 0x100) {
            out.write(0x81);
            out.write(b.length);
        } else if (b.length < 0x10000) {
            out.write(0x82);
            out.write(b.length >> 8);
            out.write(b.length & 0xFF);
        } else {
            out.write(0x83);
            out.write(b.length >> 16);
            out.write((b.length >> 8) & 0xFF);
            out.write(b.length & 0xFF);
        }
        out.write(b, 0, b.length);
        return out.toByteArray();
    }

    static byte[] seq(byte[]... p) {
        return tlv(0x30, p);
    }

    static byte[] set(byte[]... p) {
        return tlv(0x31, p);
    }

    static byte[] explicit(int n, byte[]... p) {
        return tlv(0xA0 | n, p);
    }

    static byte[] nul() {
        return new byte[]{0x05, 0x00};
    }

    static byte[] integer(BigInteger v) {
        return tlv(0x02, v.toByteArray());
    }

    static byte[] octets(byte[] b) {
        return tlv(0x04, b);
    }

    static byte[] bitString(byte[] b) {
        byte[] withUnused = new byte[b.length + 1];
        System.arraycopy(b, 0, withUnused, 1, b.length);
        return tlv(0x03, withUnused);
    }

    static byte[] utf8(String s) {
        try {
            return tlv(0x0C, s.getBytes("UTF-8"));
        } catch (java.io.UnsupportedEncodingException e) {
            throw new IllegalStateException(e);
        }
    }

    static byte[] oid(String dotted) {
        StringTokenizer st = new StringTokenizer(dotted, ".");
        int first = Integer.parseInt(st.nextToken());
        int second = Integer.parseInt(st.nextToken());
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        out.write(first * 40 + second);
        while (st.hasMoreTokens()) {
            long v = Long.parseLong(st.nextToken());
            byte[] tmp = new byte[10];
            int n = 0;
            tmp[n++] = (byte) (v & 0x7F);
            v >>= 7;
            while (v > 0) {
                tmp[n++] = (byte) ((v & 0x7F) | 0x80);
                v >>= 7;
            }
            for (int i = n - 1; i >= 0; i--) {
                out.write(tmp[i]);
            }
        }
        return tlv(0x06, out.toByteArray());
    }

    static byte[] utcTime(Date d) {
        SimpleDateFormat f = new SimpleDateFormat("yyMMddHHmmss'Z'");
        f.setTimeZone(TimeZone.getTimeZone("UTC"));
        try {
            return tlv(0x17, f.format(d).getBytes("US-ASCII"));
        } catch (java.io.UnsupportedEncodingException e) {
            throw new IllegalStateException(e);
        }
    }

    static byte[] algorithm(String oid, boolean withNull) {
        return withNull ? seq(oid(oid), nul()) : seq(oid(oid));
    }

    static byte[] name(String commonName) {
        return seq(set(seq(oid(COMMON_NAME), utf8(commonName))));
    }

    static byte[] sign(KeyPair kp, byte[] data) throws GeneralSecurityException {
        Signature s = Signature.getInstance("SHA1withRSA");
        s.initSign(kp.getPrivate());
        s.update(data);
        return s.sign();
    }

    /** A self-signed X.509 v3 certificate, valid for 20 years. */
    static byte[] selfSignedCert(KeyPair kp, String commonName, BigInteger serial) throws GeneralSecurityException {
        long now = System.currentTimeMillis();
        Date from = new Date(now - 24L * 3600 * 1000);
        Date to = new Date(now + 20L * 365 * 24 * 3600 * 1000);
        byte[] tbs = seq(
                explicit(0, integer(BigInteger.valueOf(2))),
                integer(serial),
                algorithm(SHA1_WITH_RSA, true),
                name(commonName),
                seq(utcTime(from), utcTime(to)),
                name(commonName),
                kp.getPublic().getEncoded());
        return seq(tbs, algorithm(SHA1_WITH_RSA, true), bitString(sign(kp, tbs)));
    }

    static BigInteger randomSerial() {
        return new BigInteger(62, new Random()).add(BigInteger.ONE);
    }

    /** The META-INF/CERT.RSA block: a PKCS#7 SignedData over the .SF bytes, signed with SHA1withRSA. */
    static byte[] signatureBlock(KeyPair kp, byte[] cert, BigInteger serial, String commonName, byte[] sfBytes)
            throws GeneralSecurityException {
        byte[] signerInfo = seq(
                integer(BigInteger.ONE),
                seq(name(commonName), integer(serial)),
                algorithm(SHA1, true),
                algorithm(RSA, true),
                octets(sign(kp, sfBytes)));
        byte[] signedData = seq(
                integer(BigInteger.ONE),
                set(algorithm(SHA1, true)),
                seq(oid(DATA)),
                explicit(0, cert),
                set(signerInfo));
        return seq(oid(SIGNED_DATA), explicit(0, signedData));
    }
}
