#!/bin/sh
# Build the experimental package: the runtime helper, the two tool programs, and the install zip.
#
# Needs: a JDK (javac, jar; 11 or newer), the Android SDK's d8 and an android.jar, and baksmali.jar and
# smali.jar (2.5.x). Nothing from a vehicle is needed.
#
#   export BAKSMALI_JAR=/path/to/baksmali.jar
#   export SMALI_JAR=/path/to/smali.jar
#   export D8=$HOME/Library/Android/sdk/build-tools/36.0.0/d8
#   export ANDROID_JAR=$HOME/Library/Android/sdk/platforms/android-36/android.jar
#   sh experimental/build.sh 0.1.0
#
# Output: experimental/dist/ev3-persist-experimental-<version>.zip
set -eu
cd "$(dirname "$0")"
VERSION=${1:?usage: build.sh <version>}
for v in BAKSMALI_JAR SMALI_JAR D8 ANDROID_JAR; do
    eval "val=\${$v:-}"
    [ -n "$val" ] && [ -e "$val" ] || { echo "set $v to an existing path" >&2; exit 1; }
done
for t in javac jar zip; do command -v "$t" > /dev/null 2>&1 || { echo "install $t first" >&2; exit 1; }; done

OUT=$(pwd)/build
rm -rf "$OUT"
mkdir -p "$OUT/rt" "$OUT/stub" "$OUT/rtdex" "$OUT/bak" "$OUT/asm" "$OUT/bakdex" "$OUT/asmdex" "$OUT/pkg/tools" dist

# 1. runtime helper: Java -> class -> dex -> smali text (the compile-only Bridge stub is left out)
javac --release 8 -cp "$ANDROID_JAR" -d "$OUT/rt" java/runtime/com/gen5w/persist/*.java java/stubs/com/gen5w/persist/Bridge.java
mkdir -p "$OUT/stub/com/gen5w/persist"
cp "$OUT/rt/com/gen5w/persist/Bridge.class" "$OUT/stub/com/gen5w/persist/"
# shellcheck disable=SC2046
"$D8" --release --min-api 19 --lib "$ANDROID_JAR" --classpath "$OUT/stub" --output "$OUT/rtdex" \
    $(find "$OUT/rt" -name '*.class' ! -name 'Bridge.class')
java -jar "$BAKSMALI_JAR" d "$OUT/rtdex/classes.dex" -o "$OUT/pkg/helper" > /dev/null

# 2. the two tool halves, each with its own library, converted to dex
javac --release 8 -cp "$BAKSMALI_JAR" -d "$OUT/bak" $(ls java/tool/com/gen5w/persist/tool/*.java | grep -v AsmTool)
javac --release 8 -cp "$SMALI_JAR" -d "$OUT/asm" java/tool/com/gen5w/persist/tool/AsmTool.java
(cd "$OUT/bak" && jar cf ../ours-bak.jar com)
(cd "$OUT/asm" && jar cf ../ours-asm.jar com)
"$D8" --release --min-api 19 --lib "$ANDROID_JAR" --output "$OUT/bakdex" "$OUT/ours-bak.jar" "$BAKSMALI_JAR"
"$D8" --release --min-api 19 --lib "$ANDROID_JAR" --output "$OUT/asmdex" "$OUT/ours-asm.jar" "$SMALI_JAR"
(cd "$OUT/bakdex" && zip -q "$OUT/pkg/tools/persist-bak.jar" classes.dex)
(cd "$OUT/asmdex" && zip -q "$OUT/pkg/tools/persist-asm.jar" classes.dex)

# 3. the package
cp -R package/. "$OUT/pkg/"
cp THIRD_PARTY_NOTICES.md "$OUT/pkg/"
sed -i.bak "s/^package-version=.*/package-version=$VERSION/" "$OUT/pkg/NEMESIS.data"
rm -f "$OUT/pkg/NEMESIS.data.bak"
ZIP=$(pwd)/dist/ev3-persist-experimental-$VERSION.zip
rm -f "$ZIP"
(cd "$OUT/pkg" && zip -q -r "$ZIP" NEMESIS.data scripts tools helper THIRD_PARTY_NOTICES.md)
echo "built $ZIP"
unzip -l "$ZIP" | tail -1
