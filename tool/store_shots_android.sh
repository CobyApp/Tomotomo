#!/usr/bin/env bash
# Captures raw Play-store screenshots on an Android emulator, in every language.
#
# Android needs its own captures: an iOS screenshot rescaled to a Play size still
# shows the iPhone status bar and the Dynamic Island, which is the wrong platform
# in an Android listing. Everything else — one build, config through a file, no
# rebuild per language — mirrors tool/store_shots.sh.
#
# Unlike the simulator, adb can tap, so this run is fully automated.
#
#   ./tool/store_shots_android.sh
#
# Output: build/store_shots_android/<lang>/<screen>.png at the device's native
# resolution.
set -euo pipefail

BUNDLE=com.dime.tomotomo
AVD=Medium_Phone_API_36.1
LANGS=(ko ja en zh)
OUT=build/store_shots_android

export ANDROID_HOME="${ANDROID_HOME:-$HOME/Library/Android/sdk}"
export PATH="$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator:$PATH"

cd "$(dirname "$0")/.."

if ! adb shell true >/dev/null 2>&1; then
  echo "Starting $AVD…"
  nohup emulator -avd "$AVD" -no-snapshot-save -no-boot-anim >/dev/null 2>&1 &
  adb wait-for-device
fi
until [ "$(adb shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" = "1" ]; do
  sleep 2
done
echo "Emulator: $(adb shell getprop ro.product.model | tr -d '\r') $(adb shell wm size | tr -d '\r')"

echo "Building the screenshot harness…"
flutter build apk --debug -t lib/main_store_shots.dart >/dev/null
adb install -r build/app/outputs/flutter-apk/app-debug.apk >/dev/null

# The config file lives in the app's private files dir, reachable only through
# run-as — which works because this is a debuggable build.
write_config() {
  # `pm clear` removes app_flutter, and the app only recreates it once Hive has
  # initialized — later than the launch returning. Create it rather than waiting.
  adb shell run-as "$BUNDLE" mkdir -p app_flutter
  printf '{"lang":"%s","screen":"%s"}' "$1" "$2" |
    adb shell "run-as $BUNDLE sh -c 'cat > app_flutter/shot_config.json'"
}

grab() { adb exec-out screencap -p > "$1"; }

# Window focus arrives while Flutter is still on the splash, and the first launch
# after `pm clear` also re-seeds, so a fixed sleep captured a white splash screen.
# Poll the pixels instead: the splash is white where the app is pink.
wait_for_ui() {
  local tmp="${TMPDIR:-/tmp}/shot_ready.png"
  for _ in $(seq 1 40); do
    grab "$tmp"
    if python3 -c "
import sys
from PIL import Image
p = Image.open('$tmp').convert('RGB').getpixel((40, 240))
sys.exit(0 if abs(p[0]-247) < 25 and abs(p[1]-205) < 45 and abs(p[2]-245) < 25 else 1)
" 2>/dev/null; then
      sleep 1   # let the entrance animations finish
      return 0
    fi
    sleep 1
  done
  echo "the app never finished starting" >&2
  return 1
}

relaunch() {
  adb shell am force-stop "$BUNDLE"
  adb shell am start -n "$BUNDLE/.MainActivity" >/dev/null
  until adb shell dumpsys window 2>/dev/null | grep -q "mCurrentFocus.*$BUNDLE"; do
    sleep 1
  done
  wait_for_ui
}

# The (i) button moves with the length of the reply above it, which differs per
# language, so it is found by colour rather than by a fixed coordinate.
tap_info_button() {
  local shot="$1"
  local point
  point=$(python3 tool/find_info_button.py "$shot") || return 1
  adb shell input tap $point
}

for lang in "${LANGS[@]}"; do
  mkdir -p "$OUT/$lang"
  # Re-seeding needs an empty store, so clear the app's data between languages.
  adb shell pm clear "$BUNDLE" >/dev/null

  for screen in friends chats words; do
    write_config "$lang" "$screen"
    relaunch
    grab "$OUT/$lang/$screen.png"
    echo "  $lang/$screen"
  done

  # Chat room, then the study sheet inside it.
  write_config "$lang" chats
  relaunch
  adb shell input tap 540 372   # the first (and newest) chat row
  sleep 3
  grab "$OUT/$lang/chat.png"
  echo "  $lang/chat"

  tap_info_button "$OUT/$lang/chat.png"
  sleep 2
  grab "$OUT/$lang/sheet.png"
  echo "  $lang/sheet"
done

echo "Raw Android captures in $OUT"
