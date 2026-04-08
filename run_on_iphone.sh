#!/usr/bin/env sh
# Physical iPhone (iOS 26+): `flutter run` uses debug/JIT and often crashes with EXC_BAD_ACCESS (code=50).
# This script runs profile mode instead. Same as: make ios
set -e
cd "$(dirname "$0")"
exec flutter run --profile "$@"
