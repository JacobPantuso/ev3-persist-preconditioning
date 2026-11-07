.class public final Lcom/gen5w/persist/PersistUi;
.super Ljava/lang/Object;
.source "PersistUi.java"


# annotations
.annotation system Ldalvik/annotation/MemberClasses;
    value = {
        Lcom/gen5w/persist/PersistUi$Installer;,
        Lcom/gen5w/persist/PersistUi$RowClick;,
        Lcom/gen5w/persist/PersistUi$Toggle;
    }
.end annotation


# static fields
.field static final DESC:Ljava/lang/String; = "When enabled, the headunit will keep the battery conditioning mode state locked. If you\'d like to change the mode uncheck this setting first."

.field static final ROW_TAG:Ljava/lang/String; = "gen5w.persist.row"

.field private static final TAG:Ljava/lang/String; = "gen5w"

.field static final TITLE:Ljava/lang/String; = "Persist Preconditioning Mode"


# direct methods
.method private constructor <init>()V
    .registers 1

    .line 34
    invoke-direct {p0}, Ljava/lang/Object;-><init>()V

    return-void
.end method

.method static applyLock(Landroid/view/View;Landroid/view/View;Z)V
    .registers 4

    xor-int/lit8 v0, p2, 0x1

    .line 249
    invoke-virtual {p0, v0}, Landroid/view/View;->setEnabled(Z)V

    xor-int/lit8 p0, p2, 0x1

    .line 250
    invoke-virtual {p1, p0}, Landroid/view/View;->setEnabled(Z)V

    return-void
.end method

.method public static install(Landroid/content/Context;Landroid/view/View;)V
    .registers 3

    .line 40
    :try_start_0
    new-instance v0, Lcom/gen5w/persist/PersistUi$Installer;

    invoke-direct {v0, p0, p1}, Lcom/gen5w/persist/PersistUi$Installer;-><init>(Landroid/content/Context;Landroid/view/View;)V

    invoke-virtual {v0}, Lcom/gen5w/persist/PersistUi$Installer;->run()V
    :try_end_8
    .catchall {:try_start_0 .. :try_end_8} :catchall_9

    return-void

    :catchall_9
    move-exception p0

    .line 42
    const-string p1, "gen5w"

    const-string v0, "persist UI not installed; the stock screen is unchanged"

    invoke-static {p1, v0, p0}, Landroid/util/Log;->e(Ljava/lang/String;Ljava/lang/String;Ljava/lang/Throwable;)I

    return-void
.end method
