package com.gen5w.persist;

import android.content.Context;
import android.content.res.ColorStateList;
import android.content.res.Resources;
import android.graphics.drawable.Drawable;
import android.text.TextUtils;
import android.util.Log;
import android.util.TypedValue;
import android.view.Gravity;
import android.view.View;
import android.view.ViewGroup;
import android.widget.CheckBox;
import android.widget.CompoundButton;
import android.widget.FrameLayout;
import android.widget.ScrollView;
import android.widget.TextView;

import java.util.ArrayList;
import java.util.List;

/**
 * Builds the Persist row in code, so no layout resource has to be compiled.
 * Everything is looked up by resource NAME at run time, so it does not depend on one build's ids.
 * If anything goes wrong the stock screen is left (or put back) exactly as it was.
 */
public final class PersistUi {
    private static final String TAG = "gen5w";
    static final String ROW_TAG = "gen5w.persist.row";
    static final String TITLE = "Persist Preconditioning Mode";
    static final String DESC = "When enabled, the headunit will keep the battery conditioning mode state locked. "
            + "If you'd like to change the mode uncheck this setting first.";

    private PersistUi() {
    }

    /** Hook entry point: called at the end of the battery conditioning row's constructor. */
    public static void install(Context ctx, View root) {
        try {
            new Installer(ctx, root).run();
        } catch (Throwable t) {
            Log.e(TAG, "persist UI not installed; the stock screen is unchanged", t);
        }
    }

    private static final class Installer {
        private final Context ctx;
        private final View root;
        private final Resources res;
        private final String pkg;
        private final float density;

        Installer(Context ctx, View root) {
            this.ctx = ctx;
            this.root = root;
            this.res = ctx.getResources();
            this.pkg = ctx.getPackageName();
            this.density = res.getDisplayMetrics().density;
        }

        private int dp(int v) {
            return Math.round(v * density);
        }

        private int id(String name, String type) {
            return res.getIdentifier(name, type, pkg);
        }

        private ColorStateList colors(String name, int fallback) {
            try {
                int rid = id(name, "color");
                if (rid != 0) {
                    return res.getColorStateList(rid);
                }
            } catch (Throwable t) {
                Log.w(TAG, "persist: color " + name + " not found");
            }
            return ColorStateList.valueOf(fallback);
        }

        private Drawable drawable(String name) {
            try {
                int rid = id(name, "drawable");
                if (rid != 0) {
                    return res.getDrawable(rid);
                }
            } catch (Throwable t) {
                Log.w(TAG, "persist: drawable " + name + " not found");
            }
            return null;
        }

        void run() {
            if (root == null || root.findViewWithTag(ROW_TAG) != null) {
                return;
            }
            int panelId = id("eco_evsettings_battery_cond_view_layout", "id");
            int rowId = id("eco_evsettings_battery_cond_layout", "id");
            int cbId = id("eco_evsettings_battery_cond_checkbox", "id");
            if (panelId == 0 || rowId == 0 || cbId == 0) {
                Log.w(TAG, "persist: battery conditioning screen ids not found; not installing");
                return;
            }
            View panelView = root.findViewById(panelId);
            View stockRow = root.findViewById(rowId);
            View stockCb = root.findViewById(cbId);
            if (!(panelView instanceof FrameLayout) || stockRow == null || stockCb == null) {
                Log.w(TAG, "persist: unexpected screen structure; not installing");
                return;
            }
            FrameLayout panel = (FrameLayout) panelView;
            boolean on = PersistState.read(ctx);

            // 1. build the new views off-screen, so a failure here changes nothing
            final CheckBox cb = new CheckBox(ctx);
            FrameLayout row = buildRow(cb);
            TextView desc = buildDescription();
            cb.setChecked(on);

            // 2. find the stock description, to trim it and let it size to its text
            TextView stockDesc = null;
            String fullDesc = null;
            int descRes = id("battery_conditioning_mode_desc", "string");
            if (descRes != 0) {
                CharSequence full = res.getText(descRes);
                fullDesc = full.toString();
                for (int i = 0; i < panel.getChildCount(); i++) {
                    View k = panel.getChildAt(i);
                    if (k instanceof TextView && TextUtils.equals(((TextView) k).getText(), full)) {
                        stockDesc = (TextView) k;
                        break;
                    }
                }
            }

            // 3. move the panel's children into a taller frame inside a ScrollView; undo it on any failure
            List<View> kids = new ArrayList<View>();
            for (int i = 0; i < panel.getChildCount(); i++) {
                kids.add(panel.getChildAt(i));
            }
            panel.removeAllViews();
            try {
                FrameLayout inner = new FrameLayout(ctx);
                for (View k : kids) {
                    ViewGroup.LayoutParams lp = k.getLayoutParams();
                    if (k == stockDesc && lp != null) {
                        lp.height = ViewGroup.LayoutParams.WRAP_CONTENT;
                    }
                    inner.addView(k, lp);
                }
                inner.addView(row);
                inner.addView(desc);
                ScrollView scroll = new ScrollView(ctx);
                scroll.addView(inner, new FrameLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, dp(560)));
                panel.addView(scroll, new FrameLayout.LayoutParams(
                        ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT));
            } catch (RuntimeException e) {
                panel.removeAllViews();
                for (View k : kids) {
                    ViewGroup p = (ViewGroup) k.getParent();
                    if (p != null) {
                        p.removeView(k);
                    }
                    panel.addView(k, k.getLayoutParams());
                }
                throw e;
            }

            // 4. the stock description keeps only its first sentence
            if (stockDesc != null && fullDesc != null) {
                int cut = fullDesc.indexOf(". ");
                if (cut > 0) {
                    stockDesc.setText(fullDesc.substring(0, cut + 1));
                }
            }

            // 5. behaviour: toggling Persist saves it, locks or unlocks the stock row, and keeps the mode on
            applyLock(stockRow, stockCb, on);
            cb.setOnCheckedChangeListener(new Toggle(ctx, stockRow, stockCb));
            row.setOnClickListener(new RowClick(cb));
        }

        private FrameLayout buildRow(CheckBox cb) {
            FrameLayout row = new FrameLayout(ctx);
            row.setTag(ROW_TAG);
            FrameLayout.LayoutParams rlp = new FrameLayout.LayoutParams(dp(604), dp(72));
            rlp.topMargin = dp(214);
            row.setLayoutParams(rlp);
            Drawable bg = drawable("bt_list_selector_minimal");
            if (bg != null) {
                row.setBackgroundDrawable(bg);
            }
            row.setClickable(true);
            row.setFocusable(true);

            cb.setPadding(0, 0, 0, 0);
            int button = id("eco30_common_checkbox", "drawable");
            if (button != 0) {
                cb.setButtonDrawable(button);
            }
            cb.setClickable(false);
            cb.setLongClickable(false);
            cb.setDuplicateParentStateEnabled(true);
            FrameLayout.LayoutParams clp = new FrameLayout.LayoutParams(dp(40), dp(40));
            clp.gravity = Gravity.START;
            clp.topMargin = dp(16);
            clp.setMarginStart(dp(30));
            row.addView(cb, clp);

            TextView title = new TextView(ctx);
            title.setText(TITLE);
            title.setTextSize(TypedValue.COMPLEX_UNIT_SP, 26f);
            title.setTextColor(colors("text_eco_input_normal", 0xFFFFFFFF));
            title.setGravity(Gravity.START | Gravity.CENTER_VERTICAL);
            title.setDuplicateParentStateEnabled(true);
            FrameLayout.LayoutParams tlp = new FrameLayout.LayoutParams(
                    ViewGroup.LayoutParams.WRAP_CONTENT, dp(72));
            tlp.gravity = Gravity.START | Gravity.CENTER_VERTICAL;
            tlp.setMarginStart(dp(78));
            row.addView(title, tlp);
            return row;
        }

        private TextView buildDescription() {
            TextView tv = new TextView(ctx);
            tv.setText(DESC);
            tv.setTextSize(TypedValue.COMPLEX_UNIT_SP, 22f);
            tv.setTextColor(colors("text_eco_evsettings_desc", 0xFFBBBBBB));
            tv.setGravity(Gravity.START | Gravity.TOP);
            try {
                int rid = id("ev_y_linespacing", "dimen");
                if (rid != 0) {
                    TypedValue v = new TypedValue();
                    res.getValue(rid, v, true);
                    tv.setLineSpacing(0f, v.getFloat());
                }
            } catch (Throwable t) {
                Log.w(TAG, "persist: line spacing not applied");
            }
            FrameLayout.LayoutParams lp = new FrameLayout.LayoutParams(dp(526), ViewGroup.LayoutParams.WRAP_CONTENT);
            lp.topMargin = dp(300);
            lp.setMarginStart(dp(38));
            tv.setLayoutParams(lp);
            return tv;
        }
    }

    static void applyLock(View stockRow, View stockCb, boolean persistOn) {
        stockRow.setEnabled(!persistOn);
        stockCb.setEnabled(!persistOn);
    }

    private static final class Toggle implements CompoundButton.OnCheckedChangeListener {
        private final Context ctx;
        private final View stockRow;
        private final View stockCb;

        Toggle(Context ctx, View stockRow, View stockCb) {
            this.ctx = ctx;
            this.stockRow = stockRow;
            this.stockCb = stockCb;
        }

        @Override
        public void onCheckedChanged(CompoundButton button, boolean checked) {
            try {
                PersistState.save(ctx, checked);
                applyLock(stockRow, stockCb, checked);
                if (checked) {
                    Bridge.writeOn();
                }
            } catch (Throwable t) {
                Log.e(TAG, "persist: toggle failed", t);
            }
        }
    }

    private static final class RowClick implements View.OnClickListener {
        private final CheckBox box;

        RowClick(CheckBox box) {
            this.box = box;
        }

        @Override
        public void onClick(View v) {
            box.toggle();
        }
    }
}
