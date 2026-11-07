package android.content;

/** Test-only stand-in: a Context whose preferences live in a map. */
public abstract class Context {
    public static final int MODE_PRIVATE = 0;

    public abstract SharedPreferences getSharedPreferences(String name, int mode);
}
