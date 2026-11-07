package com.gen5w.persist.tool;

import java.io.File;

/**
 * On-device build tool. Runs under the head unit's Dalvik VM (dalvikvm) and on a normal JVM for testing.
 * Deliberately avoids anything newer than Android 4.4 (no java.nio.file, lambdas, streams or Optional).
 */
public final class Tool {
    private Tool() {
    }

    public static void main(String[] args) {
        int rc;
        try {
            rc = run(args);
        } catch (Throwable t) {
            System.err.println("tool: " + t);
            t.printStackTrace();
            rc = 2;
        }
        System.exit(rc);
    }

    static int usage() {
        System.err.println("usage: Tool md5 <file>...\n"
                + "       Tool inspect <apk>\n"
                + "       Tool deodex <odex> <frameworkDir> <outSmaliDir>\n"
                + "       Tool patch <smaliDir> <helperSmaliDir>\n"
                + "       Tool pack <stock.apk> <classes.dex> <out.apk>\n"
                + "       Tool verify <apk>\n"
                + "       Tool selftest <workDir>   (needs <workDir>/selftest.dex from AsmTool selftest)");
        return 64;
    }

    static int run(String[] a) throws Exception {
        if (a.length == 0) {
            return usage();
        }
        String cmd = a[0];
        if (cmd.equals("md5") && a.length >= 2) {
            for (int i = 1; i < a.length; i++) {
                System.out.println(Hashing.md5(new File(a[i])) + "  " + a[i]);
            }
            return 0;
        }
        if (cmd.equals("inspect") && a.length == 2) {
            return Inspect.run(new File(a[1]), System.out);
        }
        if (cmd.equals("deodex") && a.length == 4) {
            Deodex.run(new File(a[1]), new File(a[2]), new File(a[3]), Deodex.API);
            return 0;
        }
        if (cmd.equals("patch") && a.length == 3) {
            return Patcher.run(new File(a[1]), new File(a[2]), System.out);
        }
        if (cmd.equals("pack") && a.length == 4) {
            Packer.run(new File(a[1]), new File(a[2]), new File(a[3]));
            return 0;
        }
        if (cmd.equals("verify") && a.length == 2) {
            return Verify.run(new File(a[1]), System.out);
        }
        if (cmd.equals("selftest") && a.length == 2) {
            return SelfTest.run(new File(a[1]), System.out);
        }
        return usage();
    }
}
