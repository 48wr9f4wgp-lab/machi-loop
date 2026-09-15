#!/usr/bin/env python3
"""Report whether the local machine is ready for MACHI LOOP native export.

No credentials, signing identities, provisioning contents, or secrets are read.
The tool only checks OS, executable availability/version text, and Android SDK
path environment variables. Run locally before editing export presets.
"""

from __future__ import annotations

import argparse
import os
import platform
import shutil
import subprocess
import sys
from dataclasses import dataclass


@dataclass
class Check:
    name: str
    ok: bool
    detail: str
    required_for: tuple[str, ...]


def command_version(name: str, args: list[str]) -> tuple[bool, str]:
    executable = shutil.which(name)
    if executable is None:
        return False, "not found on PATH"
    try:
        completed = subprocess.run(
            [executable, *args],
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            timeout=8,
            check=False,
        )
        first_line = (completed.stdout or "").strip().splitlines()
        detail = first_line[0] if first_line else f"exit={completed.returncode}"
        return completed.returncode == 0, detail
    except (OSError, subprocess.TimeoutExpired) as exc:
        return False, f"unable to run: {exc}"


def android_checks() -> list[Check]:
    sdk_root = os.environ.get("ANDROID_SDK_ROOT") or os.environ.get("ANDROID_HOME")
    java_ok, java_detail = command_version("java", ["-version"])
    javac_ok, javac_detail = command_version("javac", ["-version"])
    adb_ok, adb_detail = command_version("adb", ["version"])
    sdkmanager_ok, sdkmanager_detail = command_version("sdkmanager", ["--version"])
    return [
        Check("Java runtime", java_ok, java_detail, ("android",)),
        Check("Java compiler", javac_ok, javac_detail, ("android",)),
        Check("Android SDK root", bool(sdk_root), sdk_root or "ANDROID_SDK_ROOT/ANDROID_HOME not set", ("android",)),
        Check("adb", adb_ok, adb_detail, ("android",)),
        # sdkmanager can legitimately live outside PATH even when SDK is usable,
        # so it is reported but not treated as a hard failure below.
        Check("sdkmanager", sdkmanager_ok, sdkmanager_detail, ()),
    ]


def ios_checks() -> list[Check]:
    system = platform.system()
    xcode_ok, xcode_detail = command_version("xcodebuild", ["-version"])
    return [
        Check("macOS host", system == "Darwin", f"host={system}", ("ios",)),
        Check("Xcode", xcode_ok, xcode_detail, ("ios",)),
    ]


def common_checks() -> list[Check]:
    godot_ok, godot_detail = command_version("godot", ["--version"])
    if not godot_ok:
        godot_ok, godot_detail = command_version("godot4", ["--version"])
    return [Check("Godot", godot_ok, godot_detail, ("android", "ios"))]


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--target", choices=("android", "ios", "all"), default="all")
    args = parser.parse_args()

    targets = {"android", "ios"} if args.target == "all" else {args.target}
    checks = common_checks() + android_checks() + ios_checks()

    print("MACHI_LOOP_NATIVE_PREFLIGHT")
    print(f"host={platform.system()} {platform.release()} architecture={platform.machine()}")
    for check in checks:
        relevance = bool(targets.intersection(check.required_for)) or not check.required_for
        if not relevance:
            continue
        status = "OK" if check.ok else "MISSING"
        optional = " optional" if not check.required_for else ""
        print(f"[{status}{optional}] {check.name}: {check.detail}")

    hard_failures = [
        check
        for check in checks
        if check.required_for and targets.intersection(check.required_for) and not check.ok
    ]
    if hard_failures:
        print("PREFLIGHT_NOT_READY")
        for check in hard_failures:
            print(f"REQUIRED: {check.name}")
        return 1

    print("PREFLIGHT_READY_FOR_TOOLCHAIN_VALIDATION")
    print("Note: this does not validate signing, package identifiers, SDK API levels, export templates, or physical-device install.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
