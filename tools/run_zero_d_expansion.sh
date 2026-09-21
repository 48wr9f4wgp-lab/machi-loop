#!/usr/bin/env bash
set -euo pipefail
isolation=$(mktemp -d)
trap 'rm -rf "$isolation"' EXIT
export XDG_DATA_HOME="$isolation/data"
export XDG_CONFIG_HOME="$isolation/config"
export AXIVA_TEST_ISOLATED=1
mkdir -p "$XDG_DATA_HOME" "$XDG_CONFIG_HOME"
bash tools/run_godot_fixture.sh res://tests/zero_d_expansion_test.gd 2>&1 | tee zero-d-expansion.log
grep -q 'AXIVA_ZERO_D_OK' zero-d-expansion.log
