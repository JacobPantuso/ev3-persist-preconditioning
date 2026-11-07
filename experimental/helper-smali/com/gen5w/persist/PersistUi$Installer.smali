.class final Lcom/gen5w/persist/PersistUi$Installer;
.super Ljava/lang/Object;
.source "PersistUi.java"


# annotations
.annotation system Ldalvik/annotation/EnclosingClass;
    value = Lcom/gen5w/persist/PersistUi;
.end annotation

.annotation system Ldalvik/annotation/InnerClass;
    accessFlags = 0x1a
    name = "Installer"
.end annotation


# instance fields
.field private final ctx:Landroid/content/Context;

.field private final density:F

.field private final pkg:Ljava/lang/String;

.field private final res:Landroid/content/res/Resources;

.field private final root:Landroid/view/View;


# direct methods
.method constructor <init>(Landroid/content/Context;Landroid/view/View;)V
    .registers 3

    .line 53
    invoke-direct {p0}, Ljava/lang/Object;-><init>()V

    .line 54
    iput-object p1, p0, Lcom/gen5w/persist/PersistUi$Installer;->ctx:Landroid/content/Context;

    .line 55
    iput-object p2, p0, Lcom/gen5w/persist/PersistUi$Installer;->root:Landroid/view/View;

    .line 56
    invoke-virtual {p1}, Landroid/content/Context;->getResources()Landroid/content/res/Resources;

    move-result-object p2

    iput-object p2, p0, Lcom/gen5w/persist/PersistUi$Installer;->res:Landroid/content/res/Resources;

    .line 57
    invoke-virtual {p1}, Landroid/content/Context;->getPackageName()Ljava/lang/String;

    move-result-object p1

    iput-object p1, p0, Lcom/gen5w/persist/PersistUi$Installer;->pkg:Ljava/lang/String;

    .line 58
    invoke-virtual {p2}, Landroid/content/res/Resources;->getDisplayMetrics()Landroid/util/DisplayMetrics;

    move-result-object p1

    iget p1, p1, Landroid/util/DisplayMetrics;->density:F

    iput p1, p0, Lcom/gen5w/persist/PersistUi$Installer;->density:F

    return-void
.end method

.method private buildDescription()Landroid/widget/TextView;
    .registers 6

    .line 225
    new-instance v0, Landroid/widget/TextView;

    iget-object v1, p0, Lcom/gen5w/persist/PersistUi$Installer;->ctx:Landroid/content/Context;

    invoke-direct {v0, v1}, Landroid/widget/TextView;-><init>(Landroid/content/Context;)V

    .line 226
    const-string v1, "When enabled, the headunit will keep the battery conditioning mode state locked. If you\'d like to change the mode uncheck this setting first."

    invoke-virtual {v0, v1}, Landroid/widget/TextView;->setText(Ljava/lang/CharSequence;)V

    const/4 v1, 0x2

    const/high16 v2, 0x41b00000    # 22.0f

    .line 227
    invoke-virtual {v0, v1, v2}, Landroid/widget/TextView;->setTextSize(IF)V

    .line 228
    const-string v1, "text_eco_evsettings_desc"

    const v2, -0x444445

    invoke-direct {p0, v1, v2}, Lcom/gen5w/persist/PersistUi$Installer;->colors(Ljava/lang/String;I)Landroid/content/res/ColorStateList;

    move-result-object v1

    invoke-virtual {v0, v1}, Landroid/widget/TextView;->setTextColor(Landroid/content/res/ColorStateList;)V

    const v1, 0x800033

    .line 229
    invoke-virtual {v0, v1}, Landroid/widget/TextView;->setGravity(I)V

    .line 231
    :try_start_24
    const-string v1, "ev_y_linespacing"

    const-string v2, "dimen"

    invoke-direct {p0, v1, v2}, Lcom/gen5w/persist/PersistUi$Installer;->id(Ljava/lang/String;Ljava/lang/String;)I

    move-result v1

    if-eqz v1, :cond_49

    .line 233
    new-instance v2, Landroid/util/TypedValue;

    invoke-direct {v2}, Landroid/util/TypedValue;-><init>()V

    .line 234
    iget-object v3, p0, Lcom/gen5w/persist/PersistUi$Installer;->res:Landroid/content/res/Resources;

    const/4 v4, 0x1

    invoke-virtual {v3, v1, v2, v4}, Landroid/content/res/Resources;->getValue(ILandroid/util/TypedValue;Z)V

    .line 235
    invoke-virtual {v2}, Landroid/util/TypedValue;->getFloat()F

    move-result v1

    const/4 v2, 0x0

    invoke-virtual {v0, v2, v1}, Landroid/widget/TextView;->setLineSpacing(FF)V
    :try_end_41
    .catchall {:try_start_24 .. :try_end_41} :catchall_42

    goto :goto_49

    .line 238
    :catchall_42
    const-string v1, "gen5w"

    const-string v2, "persist: line spacing not applied"

    invoke-static {v1, v2}, Landroid/util/Log;->w(Ljava/lang/String;Ljava/lang/String;)I

    .line 240
    :cond_49
    :goto_49
    new-instance v1, Landroid/widget/FrameLayout$LayoutParams;

    const/16 v2, 0x20e

    invoke-direct {p0, v2}, Lcom/gen5w/persist/PersistUi$Installer;->dp(I)I

    move-result v2

    const/4 v3, -0x2

    invoke-direct {v1, v2, v3}, Landroid/widget/FrameLayout$LayoutParams;-><init>(II)V

    const/16 v2, 0x12c

    .line 241
    invoke-direct {p0, v2}, Lcom/gen5w/persist/PersistUi$Installer;->dp(I)I

    move-result v2

    iput v2, v1, Landroid/widget/FrameLayout$LayoutParams;->topMargin:I

    const/16 v2, 0x26

    .line 242
    invoke-direct {p0, v2}, Lcom/gen5w/persist/PersistUi$Installer;->dp(I)I

    move-result v2

    invoke-virtual {v1, v2}, Landroid/widget/FrameLayout$LayoutParams;->setMarginStart(I)V

    .line 243
    invoke-virtual {v0, v1}, Landroid/widget/TextView;->setLayoutParams(Landroid/view/ViewGroup$LayoutParams;)V

    return-object v0
.end method

.method private buildRow(Landroid/widget/CheckBox;)Landroid/widget/FrameLayout;
    .registers 8

    .line 184
    new-instance v0, Landroid/widget/FrameLayout;

    iget-object v1, p0, Lcom/gen5w/persist/PersistUi$Installer;->ctx:Landroid/content/Context;

    invoke-direct {v0, v1}, Landroid/widget/FrameLayout;-><init>(Landroid/content/Context;)V

    .line 185
    const-string v1, "gen5w.persist.row"

    invoke-virtual {v0, v1}, Landroid/widget/FrameLayout;->setTag(Ljava/lang/Object;)V

    .line 186
    new-instance v1, Landroid/widget/FrameLayout$LayoutParams;

    const/16 v2, 0x25c

    invoke-direct {p0, v2}, Lcom/gen5w/persist/PersistUi$Installer;->dp(I)I

    move-result v2

    const/16 v3, 0x48

    invoke-direct {p0, v3}, Lcom/gen5w/persist/PersistUi$Installer;->dp(I)I

    move-result v4

    invoke-direct {v1, v2, v4}, Landroid/widget/FrameLayout$LayoutParams;-><init>(II)V

    const/16 v2, 0xd6

    .line 187
    invoke-direct {p0, v2}, Lcom/gen5w/persist/PersistUi$Installer;->dp(I)I

    move-result v2

    iput v2, v1, Landroid/widget/FrameLayout$LayoutParams;->topMargin:I

    .line 188
    invoke-virtual {v0, v1}, Landroid/widget/FrameLayout;->setLayoutParams(Landroid/view/ViewGroup$LayoutParams;)V

    .line 189
    const-string v1, "bt_list_selector_minimal"

    invoke-direct {p0, v1}, Lcom/gen5w/persist/PersistUi$Installer;->drawable(Ljava/lang/String;)Landroid/graphics/drawable/Drawable;

    move-result-object v1

    if-eqz v1, :cond_33

    .line 191
    invoke-virtual {v0, v1}, Landroid/widget/FrameLayout;->setBackgroundDrawable(Landroid/graphics/drawable/Drawable;)V

    :cond_33
    const/4 v1, 0x1

    .line 193
    invoke-virtual {v0, v1}, Landroid/widget/FrameLayout;->setClickable(Z)V

    .line 194
    invoke-virtual {v0, v1}, Landroid/widget/FrameLayout;->setFocusable(Z)V

    const/4 v2, 0x0

    .line 196
    invoke-virtual {p1, v2, v2, v2, v2}, Landroid/widget/CheckBox;->setPadding(IIII)V

    .line 197
    const-string v4, "eco30_common_checkbox"

    const-string v5, "drawable"

    invoke-direct {p0, v4, v5}, Lcom/gen5w/persist/PersistUi$Installer;->id(Ljava/lang/String;Ljava/lang/String;)I

    move-result v4

    if-eqz v4, :cond_4b

    .line 199
    invoke-virtual {p1, v4}, Landroid/widget/CheckBox;->setButtonDrawable(I)V

    .line 201
    :cond_4b
    invoke-virtual {p1, v2}, Landroid/widget/CheckBox;->setClickable(Z)V

    .line 202
    invoke-virtual {p1, v2}, Landroid/widget/CheckBox;->setLongClickable(Z)V

    .line 203
    invoke-virtual {p1, v1}, Landroid/widget/CheckBox;->setDuplicateParentStateEnabled(Z)V

    .line 204
    new-instance v2, Landroid/widget/FrameLayout$LayoutParams;

    const/16 v4, 0x28

    invoke-direct {p0, v4}, Lcom/gen5w/persist/PersistUi$Installer;->dp(I)I

    move-result v5

    invoke-direct {p0, v4}, Lcom/gen5w/persist/PersistUi$Installer;->dp(I)I

    move-result v4

    invoke-direct {v2, v5, v4}, Landroid/widget/FrameLayout$LayoutParams;-><init>(II)V

    const v4, 0x800003

    .line 205
    iput v4, v2, Landroid/widget/FrameLayout$LayoutParams;->gravity:I

    const/16 v4, 0x10

    .line 206
    invoke-direct {p0, v4}, Lcom/gen5w/persist/PersistUi$Installer;->dp(I)I

    move-result v4

    iput v4, v2, Landroid/widget/FrameLayout$LayoutParams;->topMargin:I

    const/16 v4, 0x1e

    .line 207
    invoke-direct {p0, v4}, Lcom/gen5w/persist/PersistUi$Installer;->dp(I)I

    move-result v4

    invoke-virtual {v2, v4}, Landroid/widget/FrameLayout$LayoutParams;->setMarginStart(I)V

    .line 208
    invoke-virtual {v0, p1, v2}, Landroid/widget/FrameLayout;->addView(Landroid/view/View;Landroid/view/ViewGroup$LayoutParams;)V

    .line 210
    new-instance p1, Landroid/widget/TextView;

    iget-object v2, p0, Lcom/gen5w/persist/PersistUi$Installer;->ctx:Landroid/content/Context;

    invoke-direct {p1, v2}, Landroid/widget/TextView;-><init>(Landroid/content/Context;)V

    .line 211
    const-string v2, "Persist Preconditioning Mode"

    invoke-virtual {p1, v2}, Landroid/widget/TextView;->setText(Ljava/lang/CharSequence;)V

    const/4 v2, 0x2

    const/high16 v4, 0x41d00000    # 26.0f

    .line 212
    invoke-virtual {p1, v2, v4}, Landroid/widget/TextView;->setTextSize(IF)V

    .line 213
    const-string v2, "text_eco_input_normal"

    const/4 v4, -0x1

    invoke-direct {p0, v2, v4}, Lcom/gen5w/persist/PersistUi$Installer;->colors(Ljava/lang/String;I)Landroid/content/res/ColorStateList;

    move-result-object v2

    invoke-virtual {p1, v2}, Landroid/widget/TextView;->setTextColor(Landroid/content/res/ColorStateList;)V

    const v2, 0x800013

    .line 214
    invoke-virtual {p1, v2}, Landroid/widget/TextView;->setGravity(I)V

    .line 215
    invoke-virtual {p1, v1}, Landroid/widget/TextView;->setDuplicateParentStateEnabled(Z)V

    .line 216
    new-instance v1, Landroid/widget/FrameLayout$LayoutParams;

    const/4 v4, -0x2

    .line 217
    invoke-direct {p0, v3}, Lcom/gen5w/persist/PersistUi$Installer;->dp(I)I

    move-result v3

    invoke-direct {v1, v4, v3}, Landroid/widget/FrameLayout$LayoutParams;-><init>(II)V

    .line 218
    iput v2, v1, Landroid/widget/FrameLayout$LayoutParams;->gravity:I

    const/16 v2, 0x4e

    .line 219
    invoke-direct {p0, v2}, Lcom/gen5w/persist/PersistUi$Installer;->dp(I)I

    move-result v2

    invoke-virtual {v1, v2}, Landroid/widget/FrameLayout$LayoutParams;->setMarginStart(I)V

    .line 220
    invoke-virtual {v0, p1, v1}, Landroid/widget/FrameLayout;->addView(Landroid/view/View;Landroid/view/ViewGroup$LayoutParams;)V

    return-object v0
.end method

.method private colors(Ljava/lang/String;I)Landroid/content/res/ColorStateList;
    .registers 5

    .line 71
    :try_start_0
    const-string v0, "color"

    invoke-direct {p0, p1, v0}, Lcom/gen5w/persist/PersistUi$Installer;->id(Ljava/lang/String;Ljava/lang/String;)I

    move-result v0

    if-eqz v0, :cond_27

    .line 73
    iget-object v1, p0, Lcom/gen5w/persist/PersistUi$Installer;->res:Landroid/content/res/Resources;

    invoke-virtual {v1, v0}, Landroid/content/res/Resources;->getColorStateList(I)Landroid/content/res/ColorStateList;

    move-result-object p1
    :try_end_e
    .catchall {:try_start_0 .. :try_end_e} :catchall_f

    return-object p1

    .line 76
    :catchall_f
    new-instance v0, Ljava/lang/StringBuilder;

    const-string v1, "persist: color "

    invoke-direct {v0, v1}, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V

    invoke-virtual {v0, p1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    const-string p1, " not found"

    invoke-virtual {v0, p1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    invoke-virtual {v0}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object p1

    const-string v0, "gen5w"

    invoke-static {v0, p1}, Landroid/util/Log;->w(Ljava/lang/String;Ljava/lang/String;)I

    .line 78
    :cond_27
    invoke-static {p2}, Landroid/content/res/ColorStateList;->valueOf(I)Landroid/content/res/ColorStateList;

    move-result-object p1

    return-object p1
.end method

.method private dp(I)I
    .registers 3

    int-to-float p1, p1

    .line 62
    iget v0, p0, Lcom/gen5w/persist/PersistUi$Installer;->density:F

    mul-float p1, p1, v0

    invoke-static {p1}, Ljava/lang/Math;->round(F)I

    move-result p1

    return p1
.end method

.method private drawable(Ljava/lang/String;)Landroid/graphics/drawable/Drawable;
    .registers 4

    .line 83
    :try_start_0
    const-string v0, "drawable"

    invoke-direct {p0, p1, v0}, Lcom/gen5w/persist/PersistUi$Installer;->id(Ljava/lang/String;Ljava/lang/String;)I

    move-result v0

    if-eqz v0, :cond_27

    .line 85
    iget-object v1, p0, Lcom/gen5w/persist/PersistUi$Installer;->res:Landroid/content/res/Resources;

    invoke-virtual {v1, v0}, Landroid/content/res/Resources;->getDrawable(I)Landroid/graphics/drawable/Drawable;

    move-result-object p1
    :try_end_e
    .catchall {:try_start_0 .. :try_end_e} :catchall_f

    return-object p1

    .line 88
    :catchall_f
    new-instance v0, Ljava/lang/StringBuilder;

    const-string v1, "persist: drawable "

    invoke-direct {v0, v1}, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V

    invoke-virtual {v0, p1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    const-string p1, " not found"

    invoke-virtual {v0, p1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    invoke-virtual {v0}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object p1

    const-string v0, "gen5w"

    invoke-static {v0, p1}, Landroid/util/Log;->w(Ljava/lang/String;Ljava/lang/String;)I

    :cond_27
    const/4 p1, 0x0

    return-object p1
.end method

.method private id(Ljava/lang/String;Ljava/lang/String;)I
    .registers 5

    .line 66
    iget-object v0, p0, Lcom/gen5w/persist/PersistUi$Installer;->res:Landroid/content/res/Resources;

    iget-object v1, p0, Lcom/gen5w/persist/PersistUi$Installer;->pkg:Ljava/lang/String;

    invoke-virtual {v0, p1, p2, v1}, Landroid/content/res/Resources;->getIdentifier(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)I

    move-result p1

    return p1
.end method


# virtual methods
.method run()V
    .registers 17

    move-object/from16 v1, p0

    .line 94
    iget-object v0, v1, Lcom/gen5w/persist/PersistUi$Installer;->root:Landroid/view/View;

    if-eqz v0, :cond_15d

    const-string v2, "gen5w.persist.row"

    invoke-virtual {v0, v2}, Landroid/view/View;->findViewWithTag(Ljava/lang/Object;)Landroid/view/View;

    move-result-object v0

    if-eqz v0, :cond_10

    goto/16 :goto_15d

    .line 97
    :cond_10
    const-string v0, "eco_evsettings_battery_cond_view_layout"

    const-string v2, "id"

    invoke-direct {v1, v0, v2}, Lcom/gen5w/persist/PersistUi$Installer;->id(Ljava/lang/String;Ljava/lang/String;)I

    move-result v0

    .line 98
    const-string v3, "eco_evsettings_battery_cond_layout"

    invoke-direct {v1, v3, v2}, Lcom/gen5w/persist/PersistUi$Installer;->id(Ljava/lang/String;Ljava/lang/String;)I

    move-result v3

    .line 99
    const-string v4, "eco_evsettings_battery_cond_checkbox"

    invoke-direct {v1, v4, v2}, Lcom/gen5w/persist/PersistUi$Installer;->id(Ljava/lang/String;Ljava/lang/String;)I

    move-result v2

    .line 100
    const-string v4, "gen5w"

    if-eqz v0, :cond_158

    if-eqz v3, :cond_158

    if-nez v2, :cond_2e

    goto/16 :goto_158

    .line 104
    :cond_2e
    iget-object v5, v1, Lcom/gen5w/persist/PersistUi$Installer;->root:Landroid/view/View;

    invoke-virtual {v5, v0}, Landroid/view/View;->findViewById(I)Landroid/view/View;

    move-result-object v0

    .line 105
    iget-object v5, v1, Lcom/gen5w/persist/PersistUi$Installer;->root:Landroid/view/View;

    invoke-virtual {v5, v3}, Landroid/view/View;->findViewById(I)Landroid/view/View;

    move-result-object v3

    .line 106
    iget-object v5, v1, Lcom/gen5w/persist/PersistUi$Installer;->root:Landroid/view/View;

    invoke-virtual {v5, v2}, Landroid/view/View;->findViewById(I)Landroid/view/View;

    move-result-object v2

    .line 107
    instance-of v5, v0, Landroid/widget/FrameLayout;

    if-eqz v5, :cond_152

    if-eqz v3, :cond_152

    if-nez v2, :cond_4a

    goto/16 :goto_152

    .line 111
    :cond_4a
    move-object v4, v0

    check-cast v4, Landroid/widget/FrameLayout;

    .line 112
    iget-object v0, v1, Lcom/gen5w/persist/PersistUi$Installer;->ctx:Landroid/content/Context;

    invoke-static {v0}, Lcom/gen5w/persist/PersistState;->read(Landroid/content/Context;)Z

    move-result v0

    .line 115
    new-instance v5, Landroid/widget/CheckBox;

    iget-object v6, v1, Lcom/gen5w/persist/PersistUi$Installer;->ctx:Landroid/content/Context;

    invoke-direct {v5, v6}, Landroid/widget/CheckBox;-><init>(Landroid/content/Context;)V

    .line 116
    invoke-direct {v1, v5}, Lcom/gen5w/persist/PersistUi$Installer;->buildRow(Landroid/widget/CheckBox;)Landroid/widget/FrameLayout;

    move-result-object v6

    .line 117
    invoke-direct {v1}, Lcom/gen5w/persist/PersistUi$Installer;->buildDescription()Landroid/widget/TextView;

    move-result-object v7

    .line 118
    invoke-virtual {v5, v0}, Landroid/widget/CheckBox;->setChecked(Z)V

    .line 123
    const-string v8, "battery_conditioning_mode_desc"

    const-string v9, "string"

    invoke-direct {v1, v8, v9}, Lcom/gen5w/persist/PersistUi$Installer;->id(Ljava/lang/String;Ljava/lang/String;)I

    move-result v8

    const/4 v9, 0x0

    if-eqz v8, :cond_9a

    .line 125
    iget-object v11, v1, Lcom/gen5w/persist/PersistUi$Installer;->res:Landroid/content/res/Resources;

    invoke-virtual {v11, v8}, Landroid/content/res/Resources;->getText(I)Ljava/lang/CharSequence;

    move-result-object v8

    .line 126
    invoke-interface {v8}, Ljava/lang/CharSequence;->toString()Ljava/lang/String;

    move-result-object v11

    const/4 v12, 0x0

    .line 127
    :goto_7b
    invoke-virtual {v4}, Landroid/widget/FrameLayout;->getChildCount()I

    move-result v13

    if-ge v12, v13, :cond_9b

    .line 128
    invoke-virtual {v4, v12}, Landroid/widget/FrameLayout;->getChildAt(I)Landroid/view/View;

    move-result-object v13

    .line 129
    instance-of v14, v13, Landroid/widget/TextView;

    if-eqz v14, :cond_97

    check-cast v13, Landroid/widget/TextView;

    invoke-virtual {v13}, Landroid/widget/TextView;->getText()Ljava/lang/CharSequence;

    move-result-object v14

    invoke-static {v14, v8}, Landroid/text/TextUtils;->equals(Ljava/lang/CharSequence;Ljava/lang/CharSequence;)Z

    move-result v14

    if-eqz v14, :cond_97

    move-object v9, v13

    goto :goto_9b

    :cond_97
    add-int/lit8 v12, v12, 0x1

    goto :goto_7b

    :cond_9a
    move-object v11, v9

    .line 137
    :cond_9b
    :goto_9b
    new-instance v8, Ljava/util/ArrayList;

    invoke-direct {v8}, Ljava/util/ArrayList;-><init>()V

    const/4 v12, 0x0

    .line 138
    :goto_a1
    invoke-virtual {v4}, Landroid/widget/FrameLayout;->getChildCount()I

    move-result v13

    if-ge v12, v13, :cond_b1

    .line 139
    invoke-virtual {v4, v12}, Landroid/widget/FrameLayout;->getChildAt(I)Landroid/view/View;

    move-result-object v13

    invoke-interface {v8, v13}, Ljava/util/List;->add(Ljava/lang/Object;)Z

    add-int/lit8 v12, v12, 0x1

    goto :goto_a1

    .line 141
    :cond_b1
    invoke-virtual {v4}, Landroid/widget/FrameLayout;->removeAllViews()V

    .line 143
    :try_start_b4
    new-instance v12, Landroid/widget/FrameLayout;

    iget-object v13, v1, Lcom/gen5w/persist/PersistUi$Installer;->ctx:Landroid/content/Context;

    invoke-direct {v12, v13}, Landroid/widget/FrameLayout;-><init>(Landroid/content/Context;)V

    .line 144
    invoke-interface {v8}, Ljava/util/List;->iterator()Ljava/util/Iterator;

    move-result-object v13

    :goto_bf
    invoke-interface {v13}, Ljava/util/Iterator;->hasNext()Z

    move-result v14

    if-eqz v14, :cond_da

    invoke-interface {v13}, Ljava/util/Iterator;->next()Ljava/lang/Object;

    move-result-object v14

    check-cast v14, Landroid/view/View;

    .line 145
    invoke-virtual {v14}, Landroid/view/View;->getLayoutParams()Landroid/view/ViewGroup$LayoutParams;

    move-result-object v15

    if-ne v14, v9, :cond_d6

    if-eqz v15, :cond_d6

    const/4 v10, -0x2

    .line 147
    iput v10, v15, Landroid/view/ViewGroup$LayoutParams;->height:I

    .line 149
    :cond_d6
    invoke-virtual {v12, v14, v15}, Landroid/widget/FrameLayout;->addView(Landroid/view/View;Landroid/view/ViewGroup$LayoutParams;)V

    goto :goto_bf

    .line 151
    :cond_da
    invoke-virtual {v12, v6}, Landroid/widget/FrameLayout;->addView(Landroid/view/View;)V

    .line 152
    invoke-virtual {v12, v7}, Landroid/widget/FrameLayout;->addView(Landroid/view/View;)V

    .line 153
    new-instance v7, Landroid/widget/ScrollView;

    iget-object v10, v1, Lcom/gen5w/persist/PersistUi$Installer;->ctx:Landroid/content/Context;

    invoke-direct {v7, v10}, Landroid/widget/ScrollView;-><init>(Landroid/content/Context;)V

    .line 154
    new-instance v10, Landroid/widget/FrameLayout$LayoutParams;

    const/16 v13, 0x230

    invoke-direct {v1, v13}, Lcom/gen5w/persist/PersistUi$Installer;->dp(I)I

    move-result v13

    const/4 v14, -0x1

    invoke-direct {v10, v14, v13}, Landroid/widget/FrameLayout$LayoutParams;-><init>(II)V

    invoke-virtual {v7, v12, v10}, Landroid/widget/ScrollView;->addView(Landroid/view/View;Landroid/view/ViewGroup$LayoutParams;)V

    .line 155
    new-instance v10, Landroid/widget/FrameLayout$LayoutParams;

    invoke-direct {v10, v14, v14}, Landroid/widget/FrameLayout$LayoutParams;-><init>(II)V

    invoke-virtual {v4, v7, v10}, Landroid/widget/FrameLayout;->addView(Landroid/view/View;Landroid/view/ViewGroup$LayoutParams;)V
    :try_end_fe
    .catch Ljava/lang/RuntimeException; {:try_start_b4 .. :try_end_fe} :catch_12a

    if-eqz v9, :cond_114

    if-eqz v11, :cond_114

    .line 171
    const-string v4, ". "

    invoke-virtual {v11, v4}, Ljava/lang/String;->indexOf(Ljava/lang/String;)I

    move-result v4

    if-lez v4, :cond_114

    add-int/lit8 v4, v4, 0x1

    const/4 v7, 0x0

    .line 173
    invoke-virtual {v11, v7, v4}, Ljava/lang/String;->substring(II)Ljava/lang/String;

    move-result-object v4

    invoke-virtual {v9, v4}, Landroid/widget/TextView;->setText(Ljava/lang/CharSequence;)V

    .line 178
    :cond_114
    invoke-static {v3, v2, v0}, Lcom/gen5w/persist/PersistUi;->applyLock(Landroid/view/View;Landroid/view/View;Z)V

    .line 179
    new-instance v0, Lcom/gen5w/persist/PersistUi$Toggle;

    iget-object v4, v1, Lcom/gen5w/persist/PersistUi$Installer;->ctx:Landroid/content/Context;

    invoke-direct {v0, v4, v3, v2}, Lcom/gen5w/persist/PersistUi$Toggle;-><init>(Landroid/content/Context;Landroid/view/View;Landroid/view/View;)V

    invoke-virtual {v5, v0}, Landroid/widget/CheckBox;->setOnCheckedChangeListener(Landroid/widget/CompoundButton$OnCheckedChangeListener;)V

    .line 180
    new-instance v0, Lcom/gen5w/persist/PersistUi$RowClick;

    invoke-direct {v0, v5}, Lcom/gen5w/persist/PersistUi$RowClick;-><init>(Landroid/widget/CheckBox;)V

    invoke-virtual {v6, v0}, Landroid/widget/FrameLayout;->setOnClickListener(Landroid/view/View$OnClickListener;)V

    return-void

    :catch_12a
    move-exception v0

    .line 158
    invoke-virtual {v4}, Landroid/widget/FrameLayout;->removeAllViews()V

    .line 159
    invoke-interface {v8}, Ljava/util/List;->iterator()Ljava/util/Iterator;

    move-result-object v2

    :goto_132
    invoke-interface {v2}, Ljava/util/Iterator;->hasNext()Z

    move-result v3

    if-eqz v3, :cond_151

    invoke-interface {v2}, Ljava/util/Iterator;->next()Ljava/lang/Object;

    move-result-object v3

    check-cast v3, Landroid/view/View;

    .line 160
    invoke-virtual {v3}, Landroid/view/View;->getParent()Landroid/view/ViewParent;

    move-result-object v5

    check-cast v5, Landroid/view/ViewGroup;

    if-eqz v5, :cond_149

    .line 162
    invoke-virtual {v5, v3}, Landroid/view/ViewGroup;->removeView(Landroid/view/View;)V

    .line 164
    :cond_149
    invoke-virtual {v3}, Landroid/view/View;->getLayoutParams()Landroid/view/ViewGroup$LayoutParams;

    move-result-object v5

    invoke-virtual {v4, v3, v5}, Landroid/widget/FrameLayout;->addView(Landroid/view/View;Landroid/view/ViewGroup$LayoutParams;)V

    goto :goto_132

    .line 166
    :cond_151
    throw v0

    .line 108
    :cond_152
    :goto_152
    const-string v0, "persist: unexpected screen structure; not installing"

    invoke-static {v4, v0}, Landroid/util/Log;->w(Ljava/lang/String;Ljava/lang/String;)I

    return-void

    .line 101
    :cond_158
    :goto_158
    const-string v0, "persist: battery conditioning screen ids not found; not installing"

    invoke-static {v4, v0}, Landroid/util/Log;->w(Ljava/lang/String;Ljava/lang/String;)I

    :cond_15d
    :goto_15d
    return-void
.end method
