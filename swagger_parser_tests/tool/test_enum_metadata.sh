#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
bash tool/generate_metadata_fixtures.sh
dart run build_runner build
dart test test/enum_metadata_roundtrip_test.dart
