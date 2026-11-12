#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
for serializer in freezed plain jsonSerializable dartMappable; do
  dart run tool/generate_metadata_harness.dart "$serializer"
done
