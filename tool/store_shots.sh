#!/usr/bin/env bash
# Captures raw store screenshots for every supported language.
#
# One simulator build drives the whole matrix: the harness
# (lib/main_store_shots.dart) reads its language and target screen from
# NSUserDefaults, so each capture is a `defaults write` plus a relaunch rather
# than a rebuild. Output goes to build/store_shots/<lang>/<screen>.png at the
# simulator's native resolution.
#
#   ./tool/store_shots.sh
#
# The device is an iPhone 16 Pro Max: 1320x2868, which App Store Connect accepts
# for the required 6.9-inch slot (as does 1290x2796).
set -euo pipefail

BUNDLE=com.dime.tomotomo
DEVICE_NAME=shots-69
DEVICE_TYPE=com.apple.CoreSimulator.SimDeviceType.iPhone-16-Pro-Max
LANGS=(ko ja en zh)
# The chat room is a pushed route and simctl has no tap command, so it is
# captured separately (see the README note at the bottom of this file) rather
# than by adding a navigator hook to the production App for a screenshot.
SCREENS=(friends chats words settings)
OUT=build/store_shots

here() { cd "$(dirname "$0")/.."; }
here

udid=$(xcrun simctl list devices | grep "$DEVICE_NAME (" | head -1 |
  sed -E 's/.*\(([0-9A-F-]{36})\).*/\1/' || true)
if [ -z "$udid" ]; then
  echo "Creating $DEVICE_NAME…"
  runtime=$(xcrun simctl list runtimes | grep -oE 'com.apple.CoreSimulator.SimRuntime.iOS-[0-9-]+' | tail -1)
  udid=$(xcrun simctl create "$DEVICE_NAME" "$DEVICE_TYPE" "$runtime")
fi
echo "Simulator: $udid"

xcrun simctl bootstatus "$udid" -b >/dev/null 2>&1 || true

echo "Building the screenshot harness…"
flutter build ios --simulator --debug -t lib/main_store_shots.dart >/dev/null

# A clean install per run: stale seeded data would show the previous language's
# friends behind the new UI language.
xcrun simctl uninstall "$udid" "$BUNDLE" >/dev/null 2>&1 || true
xcrun simctl install "$udid" build/ios/iphonesimulator/Runner.app

# Config goes into the app's own documents directory, which only exists once
# installed. Not `simctl spawn … defaults write`: that lands in the simulator's
# preferences directory rather than the app container, so the app never saw it.
write_config() {
  local container
  container=$(xcrun simctl get_app_container "$udid" "$BUNDLE" data)
  mkdir -p "$container/Documents"
  printf '{"lang":"%s","screen":"%s"}' "$1" "$2" \
    > "$container/Documents/shot_config.json"
}

for lang in "${LANGS[@]}"; do
  mkdir -p "$OUT/$lang"
  # Re-seeding needs an empty store, so drop the container between languages.
  xcrun simctl uninstall "$udid" "$BUNDLE" >/dev/null 2>&1 || true
  xcrun simctl install "$udid" build/ios/iphonesimulator/Runner.app

  for screen in "${SCREENS[@]}"; do
    write_config "$lang" "$screen"
    xcrun simctl terminate "$udid" "$BUNDLE" >/dev/null 2>&1 || true
    xcrun simctl launch "$udid" "$BUNDLE" >/dev/null
    sleep 5

    xcrun simctl io "$udid" screenshot "$OUT/$lang/$screen.png" >/dev/null
    echo "  $lang/$screen"
  done
done

echo "Raw captures in $OUT"
echo
echo "The chat room still needs one tap per language, which simctl cannot do:"
echo "  c=\$(xcrun simctl get_app_container $udid $BUNDLE data)"
echo "  echo '{\"lang\":\"ja\",\"screen\":\"chats\"}' > \$c/Documents/shot_config.json"
echo "  xcrun simctl terminate $udid $BUNDLE; xcrun simctl launch $udid $BUNDLE"
echo "  # tap the single chat row (about 215,172 in points), then:"
echo "  xcrun simctl io $udid screenshot $OUT/<lang>/chat.png"
