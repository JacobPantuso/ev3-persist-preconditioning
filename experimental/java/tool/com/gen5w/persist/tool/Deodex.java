package com.gen5w.persist.tool;

import org.jf.baksmali.AnalysisArguments;
import org.jf.baksmali.Baksmali;
import org.jf.baksmali.BaksmaliOptions;
import org.jf.dexlib2.DexFileFactory;
import org.jf.dexlib2.Opcodes;
import org.jf.dexlib2.analysis.ClassPath;
import org.jf.dexlib2.analysis.InlineMethodResolver;
import org.jf.dexlib2.dexbacked.DexBackedDexFile;
import org.jf.dexlib2.dexbacked.DexBackedOdexFile;
import org.jf.dexlib2.iface.MultiDexContainer;
import org.jf.dexlib2.util.SyntheticAccessorResolver;

import java.io.File;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.List;

/** Turns an odex into plain smali, resolved against the head unit's own framework (what "baksmali x" does). */
final class Deodex {
    /** Dalvik field layout of Android 4.4, as used when this was first built by hand. */
    static final int API = 18;

    private Deodex() {
    }

    static void run(File odex, File frameworkDir, File outDir, int api) throws IOException {
        Opcodes opcodes = Opcodes.forApi(api);
        MultiDexContainer<? extends DexBackedDexFile> container = DexFileFactory.loadDexContainer(odex, opcodes);
        List<String> names = container.getDexEntryNames();
        if (names.size() != 1) {
            throw new IOException("expected one dex in " + odex + ", found " + names.size());
        }
        MultiDexContainer.DexEntry<? extends DexBackedDexFile> entry = container.getEntry(names.get(0));
        DexBackedDexFile dex = entry.getDexFile();
        if (!dex.supportsOptimizedOpcodes()) {
            throw new IOException(odex + " is not an odex (nothing to deodex)");
        }

        File[] odexFiles = frameworkDir.listFiles();
        if (odexFiles == null) {
            throw new IOException("cannot list " + frameworkDir);
        }
        List<String> boot = new ArrayList<String>();
        for (File f : odexFiles) {
            if (f.getName().endsWith(".odex")) {
                boot.add(f.getName());
            }
        }
        Collections.sort(boot);
        if (boot.isEmpty()) {
            throw new IOException("no .odex files in " + frameworkDir);
        }

        AnalysisArguments analysis = new AnalysisArguments();
        analysis.classPathDirectories = new ArrayList<String>(Arrays.asList(frameworkDir.getAbsolutePath()));
        analysis.bootClassPath = boot;
        analysis.classPath = new ArrayList<String>();
        ClassPath classPath = analysis.loadClassPathForDexFile(odex.getAbsoluteFile().getParentFile(), entry, false);

        BaksmaliOptions options = new BaksmaliOptions();
        options.apiLevel = api;
        options.parameterRegisters = true;
        options.localsDirective = false;
        options.sequentialLabels = false;
        options.debugInfo = true;
        options.codeOffsets = false;
        options.accessorComments = true;
        options.implicitReferences = false;
        options.normalizeVirtualMethods = false;
        options.registerInfo = 0;
        options.allowOdex = false;
        options.deodex = true;
        options.classPath = classPath;
        if (dex instanceof DexBackedOdexFile) {
            options.inlineResolver = InlineMethodResolver.createInlineMethodResolver(
                    ((DexBackedOdexFile) dex).getOdexVersion());
        }
        options.syntheticAccessorResolver = new SyntheticAccessorResolver(dex.getOpcodes(), dex.getClasses());

        if (!outDir.exists() && !outDir.mkdirs()) {
            throw new IOException("cannot create " + outDir);
        }
        int jobs = Math.max(1, Runtime.getRuntime().availableProcessors());
        if (!Baksmali.disassembleDexFile(dex, outDir, jobs, options, null)) {
            throw new IOException("baksmali reported errors while disassembling " + odex);
        }
    }
}
