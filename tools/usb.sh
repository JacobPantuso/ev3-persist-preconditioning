#!/bin/sh
# Copy the install zip and NEMESIS.data to a USB drive's root.
# usage: tools/usb.sh <zip> <usb-root>   (for example /Volumes/MYUSB)
set -eu
ZIP=${1:?usage: tools/usb.sh <zip> <usb-root>}
USB=${2:?usage: tools/usb.sh <zip> <usb-root>}
[ -d "$USB" ] || { echo "not a folder: $USB" >&2; exit 1; }
cp "$ZIP" "$USB/"
cp "$(dirname "$ZIP")/NEMESIS.data" "$USB/NEMESIS.data"
echo "copied to $USB. Plug it into the head unit and accept the install prompt."
