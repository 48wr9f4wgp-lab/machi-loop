#!/usr/bin/env bash
# Godot can emit script/assertion errors and still exit zero.
set -uo pipefail
if [ "$#" -ne 1 ]; then
  echo "Usage: run_godot_fixture.sh res://tests/example_test.gd" >&2
  exit 2
fi
fixture_log=$(mktemp)
trap 'rm -f "$fixture_log"' EXIT
timeout 120 "${GODOT_BIN:-godot}" --headless --path . --script "$1" 2>&1 | tee "$fixture_log"
fixture_status=$?
if [ "$fixture_status" -ne 0 ]; then
  exit "$fixture_status"
fi
if grep -Eq 'SCRIPT ERROR|Parse Error|Failed to load script|[A-Z_]+_FAILED' "$fixture_log"; then
  echo "GODOT_FIXTURE_FAILED: error diagnostic despite zero exit status" >&2
  exit 1
fi
