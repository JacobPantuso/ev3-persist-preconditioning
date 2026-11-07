#!/usr/bin/env python3
"""Apply the Persist Preconditioning UI changes to a decoded EV3 APK (apktool d output).

usage: patch_resources.py <decoded_apk_dir>

Every edit is anchored on text from the stock resources. If an anchor is missing or
appears more than once, the script stops without writing that file, so a build for an
unsupported vehicle fails loudly instead of producing a broken layout.
"""
import os
if not __debug__:
    raise SystemExit('run without -O: the anchor checks are assert statements')
import re
import sys

LAYOUT = "res/layout/layout_ev_settings_battery_cond_view.xml"
PUBLIC = "res/values/public.xml"
STRINGS = "res/values/strings.xml"

PERSIST_TITLE = "Persist Preconditioning Mode"
PERSIST_DESC = ("When enabled, the headunit will keep the battery conditioning mode state locked. "
                "If you\\'d like to change the mode uncheck this setting first.")


def once(text, old, new, label):
    count = text.count(old)
    if count != 1:
        sys.exit("patch_resources: anchor '%s' found %d times (expected 1)" % (label, count))
    return text.replace(old, new)


def patch_layout(path):
    s = open(path, encoding="utf-8").read()
    if "eco_evsettings_persist_precond_row" in s:
        sys.exit("patch_resources: layout already patched")

    # 1. the battery description grows to its text instead of a fixed 242dp box
    s = once(s,
             'android:layout_width="526.0dp" android:layout_height="242.0dp" android:layout_marginTop="94.0dp"',
             'android:layout_width="526.0dp" android:layout_height="wrap_content" android:layout_marginTop="94.0dp"',
             "battery description box")

    # 2. wrap the panel in a ScrollView so the Persist description can be reached.
    #    The root keeps its stock 360dp height; the inner frame is taller and scrolls.
    head = 'xmlns:android="http://schemas.android.com/apk/res/android">'
    s = once(s, head,
             head + '\n<ScrollView android:layout_width="match_parent" android:layout_height="match_parent">\n'
             '<FrameLayout android:layout_width="match_parent" android:layout_height="560.0dp">',
             "root start tag")
    s = s.rstrip()
    if not s.endswith("</FrameLayout>"):
        sys.exit("patch_resources: layout does not end with the root closing tag")
    body = s[:-len("</FrameLayout>")]

    # 3. the Persist row (checkbox and title laid out like the battery row) and its description
    row = (
        '    <FrameLayout android:id="@id/eco_evsettings_persist_precond_row" '
        'android:background="@drawable/bt_list_selector_minimal" android:layout_width="604.0dp" '
        'android:layout_height="72.0dp" android:layout_marginTop="214.0dp">\n'
        '        <CheckBox android:layout_gravity="start" android:id="@id/eco_evsettings_persist_precond_checkbox" '
        'android:clickable="false" android:longClickable="false" android:duplicateParentState="true" '
        'android:layout_width="40.0dp" android:layout_height="40.0dp" android:layout_marginTop="16.0dp" '
        'android:button="@drawable/eco30_common_checkbox" android:layout_marginStart="30.0dp" />\n'
        '        <TextView android:textSize="26.0sp" android:textColor="@color/text_eco_input_normal" '
        'android:gravity="start|center" android:layout_gravity="start|center" '
        'android:id="@id/eco_evsettings_persist_precond_title" android:duplicateParentState="true" '
        'android:layout_width="wrap_content" android:layout_height="72.0dp" '
        'android:text="@string/persist_precond_title" android:layout_marginStart="78.0dp" />\n'
        '    </FrameLayout>\n')
    desc = ('    <TextView android:id="@id/eco_evsettings_persist_precond_text" android:layout_width="526.0dp" '
            'android:layout_height="wrap_content" android:layout_marginTop="300.0dp" '
            'android:layout_marginStart="38.0dp" android:textSize="22.0sp" '
            'android:textColor="@color/text_eco_evsettings_desc" android:text="@string/persist_precond_desc" />\n')
    s = body + row + desc + "</FrameLayout>\n</ScrollView>\n</FrameLayout>\n"
    open(path, "w", encoding="utf-8").write(s)


def patch_public(path):
    s = open(path, encoding="utf-8").read()
    if "eco_evsettings_persist_precond_row" in s:
        sys.exit("patch_resources: public ids already patched")
    for taken in ("0x7f0b0431", "0x7f0b0432", "0x7f0b0433", "0x7f0b0434"):
        if 'id="%s"' % taken in s:
            sys.exit("patch_resources: public id %s is already used in this build" % taken)
    anchor = '    <public type="id" name="eco_evsettings_battery_cond_checkbox" id="0x7f0b024b" />'
    new_ids = (
        '    <public type="id" name="eco_evsettings_persist_precond_checkbox" id="0x7f0b0431" />\n'
        '    <public type="id" name="eco_evsettings_persist_precond_text" id="0x7f0b0432" />\n'
        '    <public type="id" name="eco_evsettings_persist_precond_row" id="0x7f0b0433" />\n'
        '    <public type="id" name="eco_evsettings_persist_precond_title" id="0x7f0b0434" />')
    s = once(s, anchor, anchor + "\n" + new_ids, "public battery checkbox id")
    open(path, "w", encoding="utf-8").write(s)


def patch_strings(path):
    s = open(path, encoding="utf-8").read()
    if "persist_precond_title" in s:
        sys.exit("patch_resources: strings already patched")
    anchor = '    <string name="battery_conditioning_mode_desc">'
    add = ('    <string name="persist_precond_title">%s</string>\n'
           '    <string name="persist_precond_desc">%s</string>\n') % (PERSIST_TITLE, PERSIST_DESC)
    s = once(s, anchor, add + anchor, "battery conditioning description string")
    open(path, "w", encoding="utf-8").write(s)


def trim_battery_description(path):
    """Keep only the first sentence of the Hyundai battery conditioning description."""
    s = open(path, encoding="utf-8").read()
    m = re.search(r'(<string name="battery_conditioning_mode_desc">)(.*?)(</string>)', s, re.S)
    if not m:
        return False
    text = m.group(2)
    cut = text.find(". ")
    if cut < 0:
        return False
    s = s[:m.start(2)] + text[:cut + 1] + s[m.end(2):]
    open(path, "w", encoding="utf-8").write(s)
    return True


def main():
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    root = sys.argv[1]
    patch_layout(os.path.join(root, LAYOUT))
    patch_public(os.path.join(root, PUBLIC))
    patch_strings(os.path.join(root, STRINGS))
    trimmed = 0
    for values_dir in os.listdir(os.path.join(root, "res")):
        if not values_dir.startswith("values"):
            continue
        p = os.path.join(root, "res", values_dir, "strings.xml")
        if os.path.exists(p) and trim_battery_description(p):
            trimmed += 1
    print("patch_resources: layout, public ids, strings done; battery description trimmed in %d files" % trimmed)


if __name__ == "__main__":
    main()
