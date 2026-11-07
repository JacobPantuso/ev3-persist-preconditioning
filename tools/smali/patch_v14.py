import os
if not __debug__:
    raise SystemExit('run without -O: the anchor checks are assert statements')
root = os.path.join(os.environ["SMALI_ROOT"], "com/hkmc/daudio/app/ev3")
def rd(p): return open(os.path.join(root, p), encoding="utf-8").read()
def wr(p, s): open(os.path.join(root, p), "w", encoding="utf-8").write(s)

CB = "Landroid/widget/CheckBox;"
K = "Lcom/hkmc/daudio/app/ev3/ui/ev_settings/PersistRowClick"

# 1. the Persist row's click listener: flips the checkbox, so a tap on the text also toggles it
wr("ui/ev_settings/PersistRowClick.smali", f""".class public final {K};
.super Ljava/lang/Object;
.source "PersistRowClick.java"


# interfaces
.implements Landroid/view/View$OnClickListener;


# instance fields
.field private final cb:{CB}


# direct methods
.method public constructor <init>({CB})V
    .registers 2

    invoke-direct {{p0}}, Ljava/lang/Object;-><init>()V

    iput-object p1, p0, {K};->cb:{CB}

    return-void
.end method


# virtual methods
.method public final onClick(Landroid/view/View;)V
    .registers 4

    iget-object v0, p0, {K};->cb:{CB}

    invoke-virtual {{v0}}, Landroid/widget/CompoundButton;->isChecked()Z

    move-result v1

    xor-int/lit8 v1, v1, 0x1

    invoke-virtual {{v0, v1}}, Landroid/widget/CompoundButton;->setChecked(Z)V

    return-void
.end method
""")

# 2. wire it up in the setup method: the row is at 0x7f0b0433, checkbox is in v0
x = rd("ui/ev_settings/x.1.smali")
i = x.rfind("    return-void\n.end method")
assert i > 0
add = f"""    iget-object v2, p0, Lcom/hkmc/daudio/app/ev3/ui/b;->bj:Landroid/view/View;

    const v3, 0x7f0b0433

    invoke-virtual {{v2, v3}}, Landroid/view/View;->findViewById(I)Landroid/view/View;

    move-result-object v2

    new-instance v3, {K};

    invoke-direct {{v3, v0}}, {K};-><init>({CB})V

    invoke-virtual {{v2, v3}}, Landroid/view/View;->setOnClickListener(Landroid/view/View$OnClickListener;)V

"""
x = x[:i] + add + x[i:]
wr("ui/ev_settings/x.1.smali", x)
print("v1.4 smali edits applied")
