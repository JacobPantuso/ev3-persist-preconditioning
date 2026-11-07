package com.gen5w.persist.tool;

/** Base64 encoder (java.util.Base64 and android.util.Base64 are not both available everywhere). */
final class B64 {
    private static final char[] T = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/".toCharArray();

    private B64() {
    }

    static String encode(byte[] b) {
        StringBuilder sb = new StringBuilder((b.length + 2) / 3 * 4);
        for (int i = 0; i < b.length; i += 3) {
            int n = (b[i] & 0xFF) << 16;
            if (i + 1 < b.length) {
                n |= (b[i + 1] & 0xFF) << 8;
            }
            if (i + 2 < b.length) {
                n |= b[i + 2] & 0xFF;
            }
            sb.append(T[(n >> 18) & 63]).append(T[(n >> 12) & 63]);
            sb.append(i + 1 < b.length ? T[(n >> 6) & 63] : '=');
            sb.append(i + 2 < b.length ? T[n & 63] : '=');
        }
        return sb.toString();
    }
}
