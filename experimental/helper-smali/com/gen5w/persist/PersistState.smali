.class public final Lcom/gen5w/persist/PersistState;
.super Ljava/lang/Object;
.source "PersistState.java"


# static fields
.field static final KEY:Ljava/lang/String; = "persist"

.field static final MAX_FORCED:I = 0x3

.field static final ON:I = 0x2

.field static final PREFS:Ljava/lang/String; = "gen5w_precond"

.field static final TAG:Ljava/lang/String; = "gen5w"

.field private static forced:I

.field private static on:Z


# direct methods
.method private constructor <init>()V
    .registers 1

    .line 23
    invoke-direct {p0}, Ljava/lang/Object;-><init>()V

    return-void
.end method

.method public static coerce(I)I
    .registers 1

    .line 68
    :try_start_0
    invoke-static {p0}, Lcom/gen5w/persist/PersistState;->coerceLocked(I)I

    move-result p0
    :try_end_4
    .catchall {:try_start_0 .. :try_end_4} :catchall_4

    :catchall_4
    return p0
.end method

.method private static declared-synchronized coerceLocked(I)I
    .registers 6

    const-string v0, "persist: keeping battery conditioning on (attempt "

    const-class v1, Lcom/gen5w/persist/PersistState;

    monitor-enter v1

    .line 75
    :try_start_5
    sget-boolean v2, Lcom/gen5w/persist/PersistState;->on:Z
    :try_end_7
    .catchall {:try_start_5 .. :try_end_7} :catchall_38

    if-nez v2, :cond_b

    .line 76
    monitor-exit v1

    return p0

    :cond_b
    const/4 v2, 0x2

    if-ne p0, v2, :cond_13

    const/4 p0, 0x0

    .line 79
    :try_start_f
    sput p0, Lcom/gen5w/persist/PersistState;->forced:I
    :try_end_11
    .catchall {:try_start_f .. :try_end_11} :catchall_38

    .line 80
    monitor-exit v1

    return v2

    .line 82
    :cond_13
    :try_start_13
    sget v3, Lcom/gen5w/persist/PersistState;->forced:I

    const/4 v4, 0x3

    if-ge v3, v4, :cond_36

    add-int/lit8 v3, v3, 0x1

    .line 83
    sput v3, Lcom/gen5w/persist/PersistState;->forced:I

    .line 84
    const-string p0, "gen5w"

    new-instance v3, Ljava/lang/StringBuilder;

    invoke-direct {v3, v0}, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V

    sget v0, Lcom/gen5w/persist/PersistState;->forced:I

    invoke-virtual {v3, v0}, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;

    const-string v0, ")"

    invoke-virtual {v3, v0}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    invoke-virtual {v3}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object v0

    invoke-static {p0, v0}, Landroid/util/Log;->d(Ljava/lang/String;Ljava/lang/String;)I
    :try_end_34
    .catchall {:try_start_13 .. :try_end_34} :catchall_38

    .line 85
    monitor-exit v1

    return v2

    .line 87
    :cond_36
    monitor-exit v1

    return p0

    :catchall_38
    move-exception p0

    :try_start_39
    monitor-exit v1
    :try_end_3a
    .catchall {:try_start_39 .. :try_end_3a} :catchall_38

    throw p0
.end method

.method public static declared-synchronized isOn()Z
    .registers 2

    const-class v0, Lcom/gen5w/persist/PersistState;

    monitor-enter v0

    .line 59
    :try_start_3
    sget-boolean v1, Lcom/gen5w/persist/PersistState;->on:Z
    :try_end_5
    .catchall {:try_start_3 .. :try_end_5} :catchall_7

    monitor-exit v0

    return v1

    :catchall_7
    move-exception v1

    :try_start_8
    monitor-exit v0
    :try_end_9
    .catchall {:try_start_8 .. :try_end_9} :catchall_7

    throw v1
.end method

.method public static load(Landroid/content/Context;)V
    .registers 1

    .line 28
    invoke-static {p0}, Lcom/gen5w/persist/PersistState;->read(Landroid/content/Context;)Z

    return-void
.end method

.method public static read(Landroid/content/Context;)Z
    .registers 4

    const/4 v0, 0x1

    .line 35
    :try_start_1
    const-string v1, "gen5w_precond"

    const/4 v2, 0x0

    invoke-virtual {p0, v1, v2}, Landroid/content/Context;->getSharedPreferences(Ljava/lang/String;I)Landroid/content/SharedPreferences;

    move-result-object p0

    const-string v1, "persist"

    invoke-interface {p0, v1, v0}, Landroid/content/SharedPreferences;->getBoolean(Ljava/lang/String;Z)Z

    move-result v0
    :try_end_e
    .catchall {:try_start_1 .. :try_end_e} :catchall_f

    goto :goto_17

    :catchall_f
    move-exception p0

    .line 37
    const-string v1, "gen5w"

    const-string v2, "persist: could not read the saved value"

    invoke-static {v1, v2, p0}, Landroid/util/Log;->e(Ljava/lang/String;Ljava/lang/String;Ljava/lang/Throwable;)I

    .line 39
    :goto_17
    invoke-static {v0}, Lcom/gen5w/persist/PersistState;->set(Z)V

    return v0
.end method

.method public static save(Landroid/content/Context;Z)V
    .registers 4

    .line 45
    invoke-static {p1}, Lcom/gen5w/persist/PersistState;->set(Z)V

    .line 47
    :try_start_3
    const-string v0, "gen5w_precond"

    const/4 v1, 0x0

    invoke-virtual {p0, v0, v1}, Landroid/content/Context;->getSharedPreferences(Ljava/lang/String;I)Landroid/content/SharedPreferences;

    move-result-object p0

    invoke-interface {p0}, Landroid/content/SharedPreferences;->edit()Landroid/content/SharedPreferences$Editor;

    move-result-object p0

    const-string v0, "persist"

    invoke-interface {p0, v0, p1}, Landroid/content/SharedPreferences$Editor;->putBoolean(Ljava/lang/String;Z)Landroid/content/SharedPreferences$Editor;

    move-result-object p0

    invoke-interface {p0}, Landroid/content/SharedPreferences$Editor;->apply()V
    :try_end_17
    .catchall {:try_start_3 .. :try_end_17} :catchall_18

    return-void

    :catchall_18
    move-exception p0

    .line 49
    const-string p1, "gen5w"

    const-string v0, "persist: could not save the value"

    invoke-static {p1, v0, p0}, Landroid/util/Log;->e(Ljava/lang/String;Ljava/lang/String;Ljava/lang/Throwable;)I

    return-void
.end method

.method private static declared-synchronized set(Z)V
    .registers 2

    const-class v0, Lcom/gen5w/persist/PersistState;

    monitor-enter v0

    .line 54
    :try_start_3
    sput-boolean p0, Lcom/gen5w/persist/PersistState;->on:Z

    const/4 p0, 0x0

    .line 55
    sput p0, Lcom/gen5w/persist/PersistState;->forced:I
    :try_end_8
    .catchall {:try_start_3 .. :try_end_8} :catchall_a

    .line 56
    monitor-exit v0

    return-void

    :catchall_a
    move-exception p0

    :try_start_b
    monitor-exit v0
    :try_end_c
    .catchall {:try_start_b .. :try_end_c} :catchall_a

    throw p0
.end method
