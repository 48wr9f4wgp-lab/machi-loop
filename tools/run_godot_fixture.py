#!/usr/bin/env python3
"""Fail CI on Godot script/assertion errors even when the process exits zero."""

import os
import re
import subprocess
import sys


def main() -> int:
    if len(sys.argv) != 2:
        print("Usage: run_godot_fixture.py res://tests/example_test.gd", file=sys.stderr)
        return 2
    result = subprocess.run(
        [os.environ.get("GODOT_BIN", "godot"), "--headless", "--path", ".",
         "--script", sys.argv[1]],
        stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, timeout=120,
    )
    print(result.stdout, end="")
    if result.returncode != 0:
        return 1
    if re.search(r"SCRIPT ERROR|Parse Error|Failed to load script|\b[A-Z_]+_FAILED\b", result.stdout):
        print("GODOT_FIXTURE_FAILED: error diagnostic despite zero exit status", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
