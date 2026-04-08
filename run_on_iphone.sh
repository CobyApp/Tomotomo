#!/usr/bin/env sh
# Physical iPhone (iOS 26+): debug JIT often crashes — default is profile (AOT).
#
# If you see: "Did not find a Dart VM Service advertised" / mDNS timeout:
#   1) Prefer USB (disable wireless-only debugging) and turn off VPN on the Mac.
#   2) Same Wi‑Fi for Mac and iPhone if using wireless; check Local Network / firewall.
#   3) Install without waiting for the VM service:  RUN_MODE=release ./run_on_iphone.sh
#   4) Try USB-only discovery:  FLUTTER_DEVICE_CONNECTION=attached ./run_on_iphone.sh
#   5) flutter upgrade (stable) — tooling fixes land often.
#
# Same as: make ios (when Makefile forwards here).
set -e
cd "$(dirname "$0")"

MODE="${RUN_MODE:-profile}"

if [ "$MODE" = "release" ]; then
  exec flutter run --release "$@"
fi

ARGS=(--profile --no-dds)
if [ -n "${FLUTTER_DEVICE_CONNECTION:-}" ]; then
  ARGS+=(--device-connection "$FLUTTER_DEVICE_CONNECTION")
fi
exec flutter run "${ARGS[@]}" "$@"
