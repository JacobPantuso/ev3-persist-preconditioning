.class final Lcom/gen5w/persist/PersistUi$Toggle;
.super Ljava/lang/Object;
.source "PersistUi.java"

# interfaces
.implements Landroid/widget/CompoundButton$OnCheckedChangeListener;


# annotations
.annotation system Ldalvik/annotation/EnclosingClass;
    value = Lcom/gen5w/persist/PersistUi;
.end annotation

.annotation system Ldalvik/annotation/InnerClass;
    accessFlags = 0x1a
    name = "Toggle"
.end annotation


# instance fields
.field private final ctx:Landroid/content/Context;

.field private final stockCb:Landroid/view/View;

.field private final stockRow:Landroid/view/View;


# direct methods
.method constructor <init>(Landroid/content/Context;Landroid/view/View;Landroid/view/View;)V
    .registers 4

    .line 258
    invoke-direct {p0}, Ljava/lang/Object;-><init>()V

    .line 259
    iput-object p1, p0, Lcom/gen5w/persist/PersistUi$Toggle;->ctx:Landroid/content/Context;

    .line 260
    iput-object p2, p0, Lcom/gen5w/persist/PersistUi$Toggle;->stockRow:Landroid/view/View;

    .line 261
    iput-object p3, p0, Lcom/gen5w/persist/PersistUi$Toggle;->stockCb:Landroid/view/View;

    return-void
.end method


# virtual methods
.method public onCheckedChanged(Landroid/widget/CompoundButton;Z)V
    .registers 4

    .line 267
    :try_start_0
    iget-object p1, p0, Lcom/gen5w/persist/PersistUi$Toggle;->ctx:Landroid/content/Context;

    invoke-static {p1, p2}, Lcom/gen5w/persist/PersistState;->save(Landroid/content/Context;Z)V

    .line 268
    iget-object p1, p0, Lcom/gen5w/persist/PersistUi$Toggle;->stockRow:Landroid/view/View;

    iget-object v0, p0, Lcom/gen5w/persist/PersistUi$Toggle;->stockCb:Landroid/view/View;

    invoke-static {p1, v0, p2}, Lcom/gen5w/persist/PersistUi;->applyLock(Landroid/view/View;Landroid/view/View;Z)V

    if-eqz p2, :cond_1a

    .line 270
    invoke-static {}, Lcom/gen5w/persist/Bridge;->writeOn()V
    :try_end_11
    .catchall {:try_start_0 .. :try_end_11} :catchall_12

    return-void

    :catchall_12
    move-exception p1

    .line 273
    const-string p2, "gen5w"

    const-string v0, "persist: toggle failed"

    invoke-static {p2, v0, p1}, Landroid/util/Log;->e(Ljava/lang/String;Ljava/lang/String;Ljava/lang/Throwable;)I

    :cond_1a
    return-void
.end method
