package com.gen5w.persist.tool;

import org.jf.smali.Smali;
import org.jf.smali.SmaliOptions;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.OutputStream;
import java.util.ArrayList;
import java.util.List;

/**
 * The smali half of the tool. It is a separate program because the smali and baksmali jars each carry a
 * trimmed copy of the same library and cannot share one class path.
 *
 * usage: AsmTool assemble <smaliDir> <out.dex>
 *        AsmTool selftest <workDir>
 */
public final class AsmTool {
    static final int API = 19;

    private AsmTool() {
    }

    public static void main(String[] a) {
        int rc;
        try {
            rc = run(a);
        } catch (Throwable t) {
            System.err.println("asm: " + t);
            t.printStackTrace();
            rc = 2;
        }
        System.exit(rc);
    }

    static int run(String[] a) throws IOException {
        if (a.length == 3 && a[0].equals("assemble")) {
            assemble(new File(a[1]), new File(a[2]));
            return 0;
        }
        if (a.length == 2 && a[0].equals("selftest")) {
            return selftest(new File(a[1]));
        }
        System.err.println("usage: AsmTool assemble <smaliDir> <out.dex> | AsmTool selftest <workDir>");
        return 64;
    }

    static void assemble(File smaliDir, File outDex) throws IOException {
        SmaliOptions options = new SmaliOptions();
        options.apiLevel = API;
        options.outputDexFile = outDex.getAbsolutePath();
        options.jobs = Math.max(1, Runtime.getRuntime().availableProcessors());
        List<String> input = new ArrayList<String>();
        input.add(smaliDir.getAbsolutePath());
        if (!Smali.assemble(options, input)) {
            throw new IOException("smali reported errors assembling " + smaliDir);
        }
        if (!outDex.isFile() || outDex.length() == 0) {
            throw new IOException("no dex produced at " + outDex);
        }
    }

    /** Assembles three tiny classes into <work>/selftest.dex, for the other half's self-test to pack and verify. */
    static int selftest(File work) throws IOException {
        System.out.println("selftest(asm): vm=" + System.getProperty("java.vm.name") + " " + System.getProperty("java.vm.version"));
        File pkg = new File(work, "asm/com/gen5w/persist");
        if (!pkg.exists() && !pkg.mkdirs()) {
            throw new IOException("cannot create " + pkg);
        }
        String[] names = {"PersistUi", "PersistState", "Bridge"};
        for (int i = 0; i < names.length; i++) {
            OutputStream o = new FileOutputStream(new File(pkg, names[i] + ".smali"));
            try {
                o.write((".class public Lcom/gen5w/persist/" + names[i] + ";\n.super Ljava/lang/Object;\n\n"
                        + ".method public static ping()V\n    .registers 1\n    return-void\n.end method\n").getBytes("UTF-8"));
            } finally {
                o.close();
            }
        }
        File dex = new File(work, "selftest.dex");
        assemble(new File(work, "asm"), dex);
        System.out.println("selftest(asm): assembled " + dex.length() + " bytes");
        System.out.println("SELFTEST-ASM OK");
        return 0;
    }
}
