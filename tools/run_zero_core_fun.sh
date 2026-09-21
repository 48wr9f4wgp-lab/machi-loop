#!/usr/bin/env bash
set -euo pipefail
ISOLATION=$(mktemp -d)
trap 'rm -rf "$ISOLATION"' EXIT
export XDG_DATA_HOME="$ISOLATION/data"
export XDG_CONFIG_HOME="$ISOLATION/config"
export AXIVA_TEST_ISOLATED=1
mkdir -p "$XDG_DATA_HOME" "$XDG_CONFIG_HOME"
timeout 240 godot --headless --path . --script res://tests/zero_core_fun_test.gd 2>&1 | tee zero-core-fun.log
if grep -E 'SCRIPT ERROR|Parse Error|Failed to load script|AXIVA_ZERO_FAILED' zero-core-fun.log; then
    exit 1
fi
grep -q 'AXIVA_ZERO_OK' zero-core-fun.log
