import os
if not __debug__:
    raise SystemExit('run without -O: the anchor checks are assert statements')
root = os.path.join(os.environ["SMALI_ROOT"], "com/hkmc/daudio/app/ev3")
def rd(p): return open(os.path.join(root, p), encoding="utf-8").read()
def wr(p, s): open(os.path.join(root, p), "w", encoding="utf-8").write(s)
def once(s, old, new):
    assert s.count(old) == 1, ("count", s.count(old), old[:70])
    return s.replace(old, new)

T = "Lcom/hkmc/daudio/app/ev3/data/a/t"

# 1. t: read the saved Persist value straight from preferences and keep the static flag in step
t = rd("data/a/t.smali").rstrip("\n")
t += f"""


.method public static gen5wReadPersist(Landroid/content/Context;)Z
    .registers 4

    const-string v0, "gen5w_precond"

    const/4 v1, 0x0

    invoke-virtual {{p0, v0, v1}}, Landroid/content/Context;->getSharedPreferences(Ljava/lang/String;I)Landroid/content/SharedPreferences;

    move-result-object v0

    const-string v1, "persist"

    const/4 v2, 0x1

    invoke-interface {{v0, v1, v2}}, Landroid/content/SharedPreferences;->getBoolean(Ljava/lang/String;Z)Z

    move-result v0

    sput-boolean v0, {T};->persistPrecond:Z

    return v0
.end method
"""
wr("data/a/t.smali", t)

# 2. checkbox setup: read the saved value from the screen's own context, not the static default
x = rd("ui/ev_settings/x.1.smali")
x = once(x,
    f"    invoke-static {{}}, {T};->isPersistPrecond()Z\n\n    move-result v1\n\n    invoke-virtual {{v0, v1}}, Landroid/widget/CompoundButton;->setChecked(Z)V",
    f"    invoke-virtual {{v0}}, Landroid/view/View;->getContext()Landroid/content/Context;\n\n    move-result-object v1\n\n    invoke-static {{v1}}, {T};->gen5wReadPersist(Landroid/content/Context;)Z\n\n    move-result v1\n\n    invoke-virtual {{v0, v1}}, Landroid/widget/CompoundButton;->setChecked(Z)V")
wr("ui/ev_settings/x.1.smali", x)
print("v1.9 smali edits applied")
