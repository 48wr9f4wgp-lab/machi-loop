#!/usr/bin/env bash
set -euo pipefail
isolation=$(mktemp -d)
trap 'rm -rf "$isolation"' EXIT
export XDG_DATA_HOME="$isolation/data"
export XDG_CONFIG_HOME="$isolation/config"
export AXIVA_TEST_ISOLATED=1
mkdir -p "$XDG_DATA_HOME" "$XDG_CONFIG_HOME"
{
    bash tools/run_godot_fixture.sh res://tests/zero_c_network_test.gd
    bash tools/run_godot_fixture.sh res://tests/zero_c_core_fun_test.gd
} 2>&1 | tee zero-c-core-fun.log
grep -q 'AXIVA_ZERO_C_NETWORK_OK' zero-c-core-fun.log
grep -q 'AXIVA_ZERO_C_OK' zero-c-core-fun.log
