package com.gen5w.persist.tool;

import java.io.File;
import java.io.PrintStream;
import java.util.Enumeration;
import java.util.zip.ZipEntry;
import java.util.zip.ZipFile;

/** Prints facts about an APK that the install script uses to decide whether it is an untouched stock file. */
final class Inspect {
    private Inspect() {
    }

    static int run(File apk, PrintStream out) throws Exception {
        ZipFile zf = new ZipFile(apk);
        try {
            int entries = 0;
            boolean dex = false;
            boolean manifest = false;
            boolean signature = false;
            Enumeration<? extends ZipEntry> en = zf.entries();
            while (en.hasMoreElements()) {
                String n = en.nextElement().getName();
                entries++;
                if (n.equals("classes.dex")) {
                    dex = true;
                } else if (n.equals("AndroidManifest.xml")) {
                    manifest = true;
                } else if (n.startsWith("META-INF/") && (n.endsWith(".RSA") || n.endsWith(".DSA") || n.endsWith(".EC"))) {
                    signature = true;
                }
            }
            out.println("entries=" + entries);
            out.println("has_dex=" + (dex ? 1 : 0));
            out.println("has_manifest=" + (manifest ? 1 : 0));
            out.println("has_signature=" + (signature ? 1 : 0));
            return manifest ? 0 : 1;
        } finally {
            zf.close();
        }
    }
}
