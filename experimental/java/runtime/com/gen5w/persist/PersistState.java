package com.gen5w.persist;

import android.content.Context;
import android.util.Log;

/**
 * Persist state shared by the settings UI and the data-store write hook.
 * Nothing in here may throw into the host app: every public method catches everything.
 */
public final class PersistState {
    static final String TAG = "gen5w";
    /** Same preferences file as the Mac-built package, so a setting survives switching methods. */
    static final String PREFS = "gen5w_precond";
    static final String KEY = "persist";
    /** The app's stored value that means "battery conditioning on". */
    static final int ON = 2;
    /** Consecutive forced writes before giving up (the car may be refusing). */
    static final int MAX_FORCED = 3;

    private static boolean on;
    private static int forced;

    private PersistState() {
    }

    /** Called from the service hook: load the saved value (default on). */
    public static void load(Context ctx) {
        read(ctx);
    }

    /** Reads the saved value (default on), updates the in-memory flag and returns it. */
    public static boolean read(Context ctx) {
        boolean v = true;
        try {
            v = ctx.getSharedPreferences(PREFS, Context.MODE_PRIVATE).getBoolean(KEY, true);
        } catch (Throwable t) {
            Log.e(TAG, "persist: could not read the saved value", t);
        }
        set(v);
        return v;
    }

    /** Saves the value and updates the in-memory flag. */
    public static void save(Context ctx, boolean v) {
        set(v);
        try {
            ctx.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit().putBoolean(KEY, v).apply();
        } catch (Throwable t) {
            Log.e(TAG, "persist: could not save the value", t);
        }
    }

    private static synchronized void set(boolean v) {
        on = v;
        forced = 0;
    }

    public static synchronized boolean isOn() {
        return on;
    }

    /**
     * Called by the patched data-store write for the battery conditioning key.
     * Returns the value that should actually be stored.
     */
    public static int coerce(int value) {
        try {
            return coerceLocked(value);
        } catch (Throwable t) {
            return value;
        }
    }

    private static synchronized int coerceLocked(int value) {
        if (!on) {
            return value;
        }
        if (value == ON) {
            forced = 0;
            return ON;
        }
        if (forced < MAX_FORCED) {
            forced++;
            Log.d(TAG, "persist: keeping battery conditioning on (attempt " + forced + ")");
            return ON;
        }
        return value;
    }
}
