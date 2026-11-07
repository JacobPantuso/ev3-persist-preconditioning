package android.util;

/** Test-only stand-in for android.util.Log so the state logic can run on a plain JVM. */
public final class Log {
    private Log() {
    }

    public static int d(String tag, String msg) {
        return 0;
    }

    public static int w(String tag, String msg) {
        return 0;
    }

    public static int e(String tag, String msg, Throwable t) {
        return 0;
    }
}
