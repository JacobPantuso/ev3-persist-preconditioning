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
X = "Lcom/hkmc/daudio/app/ev3/ui/ev_settings/x"
L = "Lcom/hkmc/daudio/app/ev3/ui/ev_settings/PersistPrecondListener"
J = "Lcom/hkmc/daudio/app/ev3/utils/j"

# 1. t: log when the forced-on write happens
t = rd("data/a/t.smali")
t = once(t, f"    sput v0, {T};->forcedCount:I\n\n    const/4 p0, 0x2",
         f"    sput v0, {T};->forcedCount:I\n\n    const-string v0, \"gen5w precond: forcing battery conditioning on\"\n\n    invoke-static {{v0}}, {J};->log(Ljava/lang/String;)V\n\n    const/4 p0, 0x2")
wr("data/a/t.smali", t)

# 2. x: after the persist checkbox is set up, lock the original row and checkbox while persist is on
x = rd("ui/ev_settings/x.1.smali")
i = x.rfind("    return-void\n.end method")
assert i > 0 and "gen5wPersistSetup" not in x[i:]
add = f"""    invoke-static {{}}, {T};->isPersistPrecond()Z

    move-result v1

    xor-int/lit8 v1, v1, 0x1

    iget-object v2, p0, {X};->kU:Landroid/widget/CheckBox;

    invoke-virtual {{v2, v1}}, Landroid/view/View;->setEnabled(Z)V

    iget-object v2, p0, {X};->kT:Landroid/widget/FrameLayout;

    invoke-virtual {{v2, v1}}, Landroid/view/View;->setEnabled(Z)V

"""
x = x[:i] + add + x[i:]
wr("ui/ev_settings/x.1.smali", x)

# 3. listener: rewrite with lock/unlock of the original row and log line
wr("ui/ev_settings/PersistPrecondListener.smali", f""".class public final {L};
.super Ljava/lang/Object;
.source "PersistPrecondListener.java"


# interfaces
.implements Landroid/widget/CompoundButton$OnCheckedChangeListener;


# direct methods
.method public constructor <init>()V
    .registers 1

    invoke-direct {{p0}}, Ljava/lang/Object;-><init>()V

    return-void
.end method


# virtual methods
.method public final onCheckedChanged(Landroid/widget/CompoundButton;Z)V
    .registers 8

    invoke-static {{p2}}, {T};->setPersistPrecond(Z)V

    const-string v0, "gen5w precond: persist toggled"

    invoke-static {{v0}}, {J};->log(Ljava/lang/String;)V

    invoke-virtual {{p1}}, Landroid/widget/CompoundButton;->getContext()Landroid/content/Context;

    move-result-object v0

    const-string v1, "gen5w_precond"

    const/4 v2, 0x0

    invoke-virtual {{v0, v1, v2}}, Landroid/content/Context;->getSharedPreferences(Ljava/lang/String;I)Landroid/content/SharedPreferences;

    move-result-object v0

    invoke-interface {{v0}}, Landroid/content/SharedPreferences;->edit()Landroid/content/SharedPreferences$Editor;

    move-result-object v0

    const-string v1, "persist"

    invoke-interface {{v0, v1, p2}}, Landroid/content/SharedPreferences$Editor;->putBoolean(Ljava/lang/String;Z)Landroid/content/SharedPreferences$Editor;

    move-result-object v0

    invoke-interface {{v0}}, Landroid/content/SharedPreferences$Editor;->apply()V

    invoke-virtual {{p1}}, Landroid/widget/CompoundButton;->getRootView()Landroid/view/View;

    move-result-object v3

    xor-int/lit8 v5, p2, 0x1

    const v4, 0x7f0b024a

    invoke-virtual {{v3, v4}}, Landroid/view/View;->findViewById(I)Landroid/view/View;

    move-result-object v4

    invoke-virtual {{v4, v5}}, Landroid/view/View;->setEnabled(Z)V

    const v4, 0x7f0b024b

    invoke-virtual {{v3, v4}}, Landroid/view/View;->findViewById(I)Landroid/view/View;

    move-result-object v4

    invoke-virtual {{v4, v5}}, Landroid/view/View;->setEnabled(Z)V

    if-eqz p2, :cond_done

    const/16 v0, 0x2b

    const/4 v1, 0x2

    invoke-static {{v0, v1}}, {T};->O(II)V

    :cond_done
    return-void
.end method
""")
print("v1.3 smali edits applied")
