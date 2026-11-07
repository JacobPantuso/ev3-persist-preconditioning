import os
if not __debug__:
    raise SystemExit('run without -O: the anchor checks are assert statements')
import re, os
root = os.path.join(os.environ["SMALI_ROOT"], "com/hkmc/daudio/app/ev3")
def rd(p): return open(os.path.join(root, p), encoding="utf-8").read()
def wr(p, s): open(os.path.join(root, p), "w", encoding="utf-8").write(s)
def once(s, old, new):
    assert s.count(old) == 1, ("match count", s.count(old), old[:80])
    return s.replace(old, new)

T = "Lcom/hkmc/daudio/app/ev3/data/a/t"
X = "Lcom/hkmc/daudio/app/ev3/ui/ev_settings/x"
S = "Lcom/hkmc/daudio/app/ev3/service/EV_Service"
L = "Lcom/hkmc/daudio/app/ev3/ui/ev_settings/PersistPrecondListener"

# 1. data/a/t: fields, coercion, wrapper around the original O(II)
t = rd("data/a/t.smali")
t = once(t, ".method public static O(II)V", ".method public static gen5wWritePrecond(II)V")
t = t.rstrip("\n") + f"""

.field public static persistPrecond:Z

.field public static forcedCount:I


.method public static isPersistPrecond()Z
    .registers 1

    sget-boolean v0, {T};->persistPrecond:Z

    return v0
.end method


.method public static setPersistPrecond(Z)V
    .registers 2

    sput-boolean p0, {T};->persistPrecond:Z

    const/4 v0, 0x0

    sput v0, {T};->forcedCount:I

    return-void
.end method


# returns the value that should actually be written for flag 43 (2 = on)
.method public static gen5wCoercePrecond(I)I
    .registers 3

    sget-boolean v0, {T};->persistPrecond:Z

    if-eqz v0, :keep

    const/4 v0, 0x2

    if-eq p0, v0, :on

    sget v0, {T};->forcedCount:I

    const/4 v1, 0x3

    if-ge v0, v1, :keep

    add-int/lit8 v0, v0, 0x1

    sput v0, {T};->forcedCount:I

    const/4 p0, 0x2

    :keep
    return p0

    :on
    const/4 v0, 0x0

    sput v0, {T};->forcedCount:I

    return p0
.end method


.method public static O(II)V
    .registers 4

    const/16 v0, 0x2b

    if-ne p0, v0, :cond_plain

    invoke-static {{p1}}, {T};->gen5wCoercePrecond(I)I

    move-result p1

    :cond_plain
    invoke-static {{p0, p1}}, {T};->gen5wWritePrecond(II)V

    return-void
.end method
"""
wr("data/a/t.smali", t)

# 2. ui/ev_settings/x: set up the persist checkbox from the constructor
x = rd("ui/ev_settings/x.1.smali")
ctor_start = x.index(".method public constructor <init>(Landroid/content/Context;Landroid/view/View;Landroid/os/Handler;Lcom/hkmc/media/MicomAudioManager;)V")
ctor_end = x.index(".end method", ctor_start)
ctor = x[ctor_start:ctor_end]
assert ctor.count("    return-void") == 1
ctor2 = ctor.replace("    return-void", f"    invoke-direct {{p0}}, {X};->gen5wPersistSetup()V\n\n    return-void")
x = x[:ctor_start] + ctor2 + x[ctor_end:]
x = x.rstrip("\n") + f"""


.method private gen5wPersistSetup()V
    .registers 4

    iget-object v0, p0, Lcom/hkmc/daudio/app/ev3/ui/b;->bj:Landroid/view/View;

    const v1, 0x7f0b0431

    invoke-virtual {{v0, v1}}, Landroid/view/View;->findViewById(I)Landroid/view/View;

    move-result-object v0

    check-cast v0, Landroid/widget/CheckBox;

    invoke-static {{}}, {T};->isPersistPrecond()Z

    move-result v1

    invoke-virtual {{v0, v1}}, Landroid/widget/CompoundButton;->setChecked(Z)V

    new-instance v1, {L};

    invoke-direct {{v1}}, {L};-><init>()V

    invoke-virtual {{v0, v1}}, Landroid/widget/CompoundButton;->setOnCheckedChangeListener(Landroid/widget/CompoundButton$OnCheckedChangeListener;)V

    return-void
.end method
"""
wr("ui/ev_settings/x.1.smali", x)

# 3. new listener class for the persist checkbox
listener = f""".class public final {L};
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
    .registers 6

    invoke-static {{p2}}, {T};->setPersistPrecond(Z)V

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

    if-eqz p2, :cond_done

    const/16 v0, 0x2b

    const/4 v1, 0x2

    invoke-static {{v0, v1}}, {T};->O(II)V

    :cond_done
    return-void
.end method
"""
open(os.path.join(root, "ui/ev_settings/PersistPrecondListener.smali"), "w", encoding="utf-8").write(listener)

# 4. EV_Service: load the saved persist flag at service start (default on)
s = rd("service/EV_Service.smali")
s = once(s, "    invoke-super {p0}, Lcom/hkmc/app/HKMCService;->onCreate()V\n",
         f"    invoke-super {{p0}}, Lcom/hkmc/app/HKMCService;->onCreate()V\n\n    invoke-direct {{p0}}, {S};->gen5wLoadPersistPrecond()V\n")
s = s.rstrip("\n") + f"""


.method private gen5wLoadPersistPrecond()V
    .registers 4

    const-string v0, "gen5w_precond"

    const/4 v1, 0x0

    invoke-virtual {{p0, v0, v1}}, Landroid/content/Context;->getSharedPreferences(Ljava/lang/String;I)Landroid/content/SharedPreferences;

    move-result-object v0

    const-string v1, "persist"

    const/4 v2, 0x1

    invoke-interface {{v0, v1, v2}}, Landroid/content/SharedPreferences;->getBoolean(Ljava/lang/String;Z)Z

    move-result v0

    invoke-static {{v0}}, {T};->setPersistPrecond(Z)V

    return-void
.end method
"""
wr("service/EV_Service.smali", s)
print("patched OK")
