#!/usr/bin/env bash
set -euo pipefail
# Do not run save fixtures in the developer's normal user:// directory.
ISOLATION=$(mktemp -d)
trap 'rm -rf "$ISOLATION"' EXIT
export XDG_DATA_HOME="$ISOLATION/data"
export XDG_CONFIG_HOME="$ISOLATION/config"
export AXIVA_TEST_ISOLATED=1
mkdir -p "$XDG_DATA_HOME" "$XDG_CONFIG_HOME"
timeout 240 godot --headless --path . --script res://tests/v42_main_play_loop_test.gd 2>&1 | tee playable-loop.log
if grep -E 'SCRIPT ERROR|Parse Error|Failed to load script|V44_MAIN_PLAY_LOOP_FAILED' playable-loop.log; then
    exit 1
fi
grep -q 'V44_MAIN_PLAY_LOOP_OK' playable-loop.log
