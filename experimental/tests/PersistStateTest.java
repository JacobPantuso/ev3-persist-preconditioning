import android.content.Context;
import android.content.SharedPreferences;
import com.gen5w.persist.PersistState;

import java.util.HashMap;
import java.util.Map;

/** Behaviour of the keep-on logic: what is written when Persist is on, off, and when the car keeps refusing. */
public final class PersistStateTest {
    private static int failures;

    private static void check(String name, boolean ok) {
        System.out.println((ok ? "ok:   " : "FAIL: ") + name);
        if (!ok) {
            failures++;
        }
    }

    /** A Context whose preferences are a plain map. */
    private static final class FakeContext extends Context {
        final Map<String, Boolean> map = new HashMap<String, Boolean>();

        @Override
        public SharedPreferences getSharedPreferences(String name, int mode) {
            return new SharedPreferences() {
                public boolean getBoolean(String key, boolean def) {
                    Boolean v = map.get(key);
                    return v == null ? def : v;
                }

                public Editor edit() {
                    return new Editor() {
                        public Editor putBoolean(String key, boolean v) {
                            map.put(key, v);
                            return this;
                        }

                        public void apply() {
                        }
                    };
                }
            };
        }
    }

    public static void main(String[] args) {
        FakeContext ctx = new FakeContext();

        check("default is on when nothing was saved", PersistState.read(ctx));
        check("on: a write of 'off' (1) is turned into 'on' (2)", PersistState.coerce(1) == 2);
        check("on: a write of 'on' (2) is left alone", PersistState.coerce(2) == 2);

        PersistState.save(ctx, false);
        check("off is remembered", !PersistState.read(ctx));
        check("off: writes are not touched", PersistState.coerce(1) == 1 && PersistState.coerce(0) == 0);

        PersistState.save(ctx, true);
        check("on is remembered", PersistState.read(ctx));
        check("on: first refusal is overridden", PersistState.coerce(1) == 2);
        check("on: second refusal is overridden", PersistState.coerce(1) == 2);
        check("on: third refusal is overridden", PersistState.coerce(1) == 2);
        check("on: after three in a row it gives up", PersistState.coerce(1) == 1);
        check("on: a real 'on' resets the count", PersistState.coerce(2) == 2 && PersistState.coerce(1) == 2);

        PersistState.save(ctx, false);
        PersistState.save(ctx, true);
        check("turning Persist off and on again resets the count", PersistState.coerce(1) == 2);

        System.out.println(failures == 0 ? "PersistState: all checks passed" : "PersistState: " + failures + " failure(s)");
        System.exit(failures == 0 ? 0 : 1);
    }
}
