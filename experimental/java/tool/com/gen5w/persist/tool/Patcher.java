package com.gen5w.persist.tool;

import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.io.PrintStream;
import java.util.ArrayList;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Adds the Persist feature to a deodexed settings app (a smali tree).
 *
 * Nothing here relies on a build's obfuscated names. Each hook is found by structure and by string
 * literals, and the engine stops with a clear message if a hook is missing or ambiguous, so an
 * unsupported build is refused instead of being patched wrongly.
 *
 * Hooks:
 *   1. the data-store write for the battery conditioning key: wrapped so the value can be kept at "on"
 *   2. the end of the battery conditioning row's constructor: builds the Persist row
 *   3. the settings service's onCreate: loads the saved Persist value
 *   4. a generated Bridge class the UI uses to write "on" through the app's own write method
 */
final class Patcher {
    private static final String RT = "Lcom/gen5w/persist/";

    private final File root;
    private final PrintStream log;

    private Patcher(File root, PrintStream log) {
        this.root = root;
        this.log = log;
    }

    static int run(File smaliDir, File helperDir, PrintStream log) throws IOException {
        try {
            new Patcher(smaliDir, log).patch(helperDir);
            return 0;
        } catch (PatchException e) {
            log.println("patch: REFUSED - " + e.getMessage());
            return 3;
        }
    }

    static final class PatchException extends Exception {
        PatchException(String m) {
            super(m);
        }
    }

    // ------------------------------------------------------------------ the patch

    private void patch(File helperDir) throws IOException, PatchException {
        File ours = new File(root, "com/gen5w/persist");
        if (ours.exists()) {
            throw new PatchException("already patched (" + ours + " exists)");
        }
        List<File> files = new ArrayList<File>();
        walk(root, files);
        log.println("patch: " + files.size() + " smali files");

        int key = findBatteryKey(files);
        log.println("patch: battery conditioning key = " + key);

        // 1. the data-store write
        File storeFile = findStoreFile(files);
        String store = classOf(read(storeFile));
        String storeText = read(storeFile);
        Method setValue = findSetValue(storeText);
        Method writer = findWriter(storeText, store, setValue.name);
        log.println("patch: store class " + store + ", setValue=" + setValue.name + ", write=" + writer.name);
        writeFile(storeFile, wrapWriter(storeText, store, writer, key));

        // 2. the battery row's constructor
        File rowFile = findRowFile(files, key);
        String rowText = read(rowFile);
        writeFile(rowFile, hookConstructor(rowText));
        log.println("patch: row class " + classOf(rowText));

        // 3. the service's onCreate
        File serviceFile = findServiceFile(files);
        String serviceText = read(serviceFile);
        writeFile(serviceFile, hookService(serviceText));
        log.println("patch: service class " + classOf(serviceText));

        // 4. Bridge and the helper classes
        writeBridge(store, writer.name, key);
        copyTree(helperDir, root);
        log.println("patch: OK");
    }

    // ------------------------------------------------------------------ discovery

    private int findBatteryKey(List<File> files) throws IOException, PatchException {
        Pattern p = Pattern.compile("INT\\.BATTERY_CONDITIONING\\[(\\d+)\\]");
        String found = null;
        for (File f : files) {
            Matcher m = p.matcher(read(f));
            while (m.find()) {
                if (found != null && !found.equals(m.group(1))) {
                    throw new PatchException("more than one battery conditioning key: " + found + ", " + m.group(1));
                }
                found = m.group(1);
            }
        }
        if (found == null) {
            throw new PatchException("battery conditioning key not found (INT.BATTERY_CONDITIONING[n])");
        }
        return Integer.parseInt(found);
    }

    private File findStoreFile(List<File> files) throws IOException, PatchException {
        File hit = null;
        for (File f : files) {
            String t = read(f);
            if (t.contains("\"Data[\"") && t.contains("\"] Set[\"")) {
                if (hit != null) {
                    throw new PatchException("more than one data-store class (" + hit.getName() + ", " + f.getName() + ")");
                }
                hit = f;
            }
        }
        if (hit == null) {
            throw new PatchException("data-store class not found");
        }
        return hit;
    }

    private Method findSetValue(String text) throws PatchException {
        Method hit = null;
        for (Method m : methods(text)) {
            if (m.body.contains("\"] Set[\"")) {
                if (hit != null) {
                    throw new PatchException("more than one method writes \"] Set[\"");
                }
                hit = m;
            }
        }
        if (hit == null || !hit.desc.equals("(II)V") || !hit.mods.contains("static")) {
            throw new PatchException("store setValue(II)V not found");
        }
        return hit;
    }

    /** public static (II)V that calls setValue(p0, p1) and has no string literals (the logging variant has them). */
    private Method findWriter(String text, String store, String setValueName) throws PatchException {
        String call = "invoke-static {p0, p1}, " + store + "->" + setValueName + "(II)V";
        Method hit = null;
        for (Method m : methods(text)) {
            if (m.mods.contains("public") && m.mods.contains("static") && m.desc.equals("(II)V")
                    && m.body.contains(call) && !m.body.contains("const-string")) {
                if (hit != null) {
                    throw new PatchException("more than one store write method (" + hit.name + ", " + m.name + ")");
                }
                hit = m;
            }
        }
        if (hit == null) {
            throw new PatchException("store write method not found");
        }
        return hit;
    }

    private File findRowFile(List<File> files, int key) throws IOException, PatchException {
        Pattern keyConst = Pattern.compile("const/16 v\\d+, 0x" + Integer.toHexString(key) + "\\s*$", Pattern.MULTILINE);
        File hit = null;
        for (File f : files) {
            String t = read(f);
            if (t.contains("\"unRestrictUserActions\"")
                    && keyConst.matcher(t).find()
                    && Pattern.compile("^\\.field .*Landroid/widget/CheckBox;", Pattern.MULTILINE).matcher(t).find()
                    && t.contains(ROW_CTOR)) {
                if (hit != null) {
                    throw new PatchException("more than one battery row class (" + hit.getName() + ", " + f.getName() + ")");
                }
                hit = f;
            }
        }
        if (hit == null) {
            throw new PatchException("battery conditioning row class not found");
        }
        return hit;
    }

    private static final String ROW_CTOR =
            ".method public constructor <init>(Landroid/content/Context;Landroid/view/View;"
                    + "Landroid/os/Handler;Lcom/hkmc/media/MicomAudioManager;)V";

    private File findServiceFile(List<File> files) throws IOException, PatchException {
        File hit = null;
        for (File f : files) {
            String t = read(f);
            if (t.contains(".super Lcom/hkmc/app/HKMCService;") && t.contains("\" On Create\"")) {
                if (hit != null) {
                    throw new PatchException("more than one settings service (" + hit.getName() + ", " + f.getName() + ")");
                }
                hit = f;
            }
        }
        if (hit == null) {
            throw new PatchException("settings service class not found");
        }
        return hit;
    }

    // ------------------------------------------------------------------ edits

    private String wrapWriter(String text, String store, Method writer, int key) throws PatchException {
        String header = ".method " + writer.mods + " " + writer.name + "(II)V";
        int h = text.indexOf(header);
        if (h < 0 || text.indexOf(header, h + 1) >= 0) {
            throw new PatchException("write method header not unique: " + header);
        }
        String renamed = text.substring(0, h) + ".method " + writer.mods + " " + writer.name + "$gen5w(II)V"
                + text.substring(h + header.length());
        String wrapper = "\n\n.method " + writer.mods + " " + writer.name + "(II)V\n"
                + "    .registers 4\n\n"
                + "    const/16 v0, " + key + "\n\n"
                + "    if-ne p0, v0, :gen5w_plain\n\n"
                + "    invoke-static {p1}, " + RT + "PersistState;->coerce(I)I\n\n"
                + "    move-result p1\n\n"
                + "    :gen5w_plain\n"
                + "    invoke-static {p0, p1}, " + store + "->" + writer.name + "$gen5w(II)V\n\n"
                + "    return-void\n"
                + ".end method\n";
        return renamed.replaceAll("\\s+$", "") + wrapper;
    }

    private String hookConstructor(String text) throws PatchException {
        int start = text.indexOf(ROW_CTOR);
        int end = text.indexOf("\n.end method", start);
        if (start < 0 || end < 0) {
            throw new PatchException("row constructor not found");
        }
        String body = text.substring(start, end);
        int ret = body.lastIndexOf("    return-void");
        if (ret < 0 || body.indexOf("    return-void") != ret) {
            throw new PatchException("row constructor does not have exactly one return-void");
        }
        String hook = "    invoke-static/range {p1 .. p2}, " + RT
                + "PersistUi;->install(Landroid/content/Context;Landroid/view/View;)V\n\n";
        return text.substring(0, start) + body.substring(0, ret) + hook + body.substring(ret) + text.substring(end);
    }

    private String hookService(String text) throws PatchException {
        String call = "    invoke-super {p0}, Lcom/hkmc/app/HKMCService;->onCreate()V\n";
        int i = text.indexOf(call);
        if (i < 0 || text.indexOf(call, i + 1) >= 0) {
            throw new PatchException("service onCreate super call not found exactly once");
        }
        String hook = "\n    invoke-static/range {p0 .. p0}, " + RT + "PersistState;->load(Landroid/content/Context;)V\n";
        return text.substring(0, i + call.length()) + hook + text.substring(i + call.length());
    }

    private void writeBridge(String store, String writerName, int key) throws IOException {
        File out = new File(root, "com/gen5w/persist/Bridge.smali");
        out.getParentFile().mkdirs();
        String smali = ".class public final " + RT + "Bridge;\n"
                + ".super Ljava/lang/Object;\n"
                + ".source \"Bridge.java\"\n\n\n"
                + ".method public static writeOn()V\n"
                + "    .registers 2\n\n"
                + "    const/16 v0, " + key + "\n\n"
                + "    const/4 v1, 0x2\n\n"
                + "    invoke-static {v0, v1}, " + store + "->" + writerName + "(II)V\n\n"
                + "    return-void\n"
                + ".end method\n";
        writeFile(out, smali);
    }

    // ------------------------------------------------------------------ smali text helpers

    static final class Method {
        String mods;
        String name;
        String desc;
        String body;
    }

    private static final Pattern METHOD_HEADER =
            Pattern.compile("^\\.method ((?:[a-z]+ )*)([^\\s(]+)\\(([^)]*)\\)(\\S+)$");

    static List<Method> methods(String text) {
        List<Method> out = new ArrayList<Method>();
        String[] lines = text.split("\n", -1);
        Method cur = null;
        StringBuilder body = null;
        for (String line : lines) {
            if (cur == null) {
                Matcher m = METHOD_HEADER.matcher(line);
                if (m.matches()) {
                    cur = new Method();
                    cur.mods = m.group(1).trim();
                    cur.name = m.group(2);
                    cur.desc = "(" + m.group(3) + ")" + m.group(4);
                    body = new StringBuilder();
                }
            } else if (line.equals(".end method")) {
                cur.body = body.toString();
                out.add(cur);
                cur = null;
            } else {
                body.append(line).append('\n');
            }
        }
        return out;
    }

    static String classOf(String text) throws PatchException {
        Matcher m = Pattern.compile("^\\.class .*?(L[^;]+;)", Pattern.MULTILINE).matcher(text);
        if (!m.find()) {
            throw new PatchException("no .class line");
        }
        return m.group(1);
    }

    // ------------------------------------------------------------------ files (java.io only: no java.nio.file on Android 4.4)

    private static void walk(File dir, List<File> out) {
        File[] kids = dir.listFiles();
        if (kids == null) {
            return;
        }
        for (File k : kids) {
            if (k.isDirectory()) {
                walk(k, out);
            } else if (k.getName().endsWith(".smali")) {
                out.add(k);
            }
        }
    }

    static String read(File f) throws IOException {
        InputStream in = new FileInputStream(f);
        try {
            ByteArrayOutputStream bo = new ByteArrayOutputStream();
            byte[] buf = new byte[1 << 16];
            int n;
            while ((n = in.read(buf)) > 0) {
                bo.write(buf, 0, n);
            }
            return new String(bo.toByteArray(), "UTF-8");
        } finally {
            in.close();
        }
    }

    static void writeFile(File f, String text) throws IOException {
        OutputStream out = new FileOutputStream(f);
        try {
            out.write(text.getBytes("UTF-8"));
        } finally {
            out.close();
        }
    }

    private static void copyTree(File from, File to) throws IOException {
        File[] kids = from.listFiles();
        if (kids == null) {
            throw new IOException("cannot read helper smali at " + from);
        }
        for (File k : kids) {
            File dest = new File(to, k.getName());
            if (k.isDirectory()) {
                if (!dest.exists() && !dest.mkdirs()) {
                    throw new IOException("cannot create " + dest);
                }
                copyTree(k, dest);
            } else {
                if (dest.exists()) {
                    throw new IOException("refusing to overwrite " + dest);
                }
                writeFile(dest, read(k));
            }
        }
    }
}
