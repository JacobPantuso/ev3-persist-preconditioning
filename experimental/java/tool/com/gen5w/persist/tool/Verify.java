package com.gen5w.persist.tool;

import org.jf.dexlib2.DexFileFactory;
import org.jf.dexlib2.Opcodes;
import org.jf.dexlib2.dexbacked.DexBackedDexFile;
import org.jf.dexlib2.iface.ClassDef;
import org.jf.dexlib2.iface.MultiDexContainer;

import java.io.File;
import java.io.InputStream;
import java.io.PrintStream;
import java.security.cert.Certificate;
import java.util.Enumeration;
import java.util.HashSet;
import java.util.Set;
import java.util.jar.JarEntry;
import java.util.jar.JarFile;

/**
 * Checks a finished APK the way the device will: every entry's digest and signature (JarFile does the same
 * check the package installer does), and that the new dex loads and contains the Persist classes.
 */
final class Verify {
    static final String[] PERSIST_TYPES = {
        "Lcom/gen5w/persist/PersistUi;",
        "Lcom/gen5w/persist/PersistState;",
        "Lcom/gen5w/persist/Bridge;"
    };

    private Verify() {
    }

    static int run(File apk, PrintStream out) throws Exception {
        return check(apk, out, PERSIST_TYPES);
    }

    static int check(File apk, PrintStream out, String[] requiredTypes) throws Exception {
        int problems = 0;

        // 1. signature and digests of every entry
        int signed = 0;
        JarFile jar = new JarFile(apk, true);
        try {
            byte[] buf = new byte[1 << 16];
            Enumeration<JarEntry> en = jar.entries();
            while (en.hasMoreElements()) {
                JarEntry e = en.nextElement();
                if (e.isDirectory() || e.getName().startsWith("META-INF/")) {
                    continue;
                }
                InputStream in = jar.getInputStream(e);
                try {
                    while (in.read(buf) > 0) {
                        // reading to the end is what triggers the digest check
                    }
                } finally {
                    in.close();
                }
                Certificate[] certs = e.getCertificates();
                if (certs == null || certs.length == 0) {
                    out.println("verify: no certificate for " + e.getName());
                    problems++;
                } else {
                    signed++;
                }
            }
        } catch (SecurityException se) {
            out.println("verify: signature check failed: " + se.getMessage());
            problems++;
        } finally {
            jar.close();
        }
        out.println("verify: " + signed + " signed entries");

        // 2. the dex loads and has the classes we expect
        MultiDexContainer<? extends DexBackedDexFile> container = DexFileFactory.loadDexContainer(apk, Opcodes.forApi(19));
        MultiDexContainer.DexEntry<? extends DexBackedDexFile> entry = container.getEntry("classes.dex");
        if (entry == null) {
            out.println("verify: no classes.dex");
            return problems + 1;
        }
        Set<String> types = new HashSet<String>();
        for (ClassDef c : entry.getDexFile().getClasses()) {
            types.add(c.getType());
        }
        out.println("verify: classes.dex defines " + types.size() + " classes");
        for (String t : requiredTypes) {
            if (!types.contains(t)) {
                out.println("verify: missing class " + t);
                problems++;
            }
        }
        out.println(problems == 0 ? "verify: OK" : "verify: " + problems + " problem(s)");
        return problems == 0 ? 0 : 4;
    }
}
