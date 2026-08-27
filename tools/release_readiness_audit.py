#!/usr/bin/env python3
"""Static release-readiness checks for MACHI LOOP.

This script intentionally focuses on high-confidence repository hygiene checks that
can run without Godot, network access, or platform SDKs. It must not inspect user
save data or generated build artifacts.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

SKIP_DIRS = {
    ".git",
    ".godot",
    "build",
    "generated",
    "vendor",
    "third_party",
}

TEXT_SUFFIXES = {
    ".gd",
    ".tscn",
    ".tres",
    ".cfg",
    ".md",
    ".txt",
    ".json",
    ".yml",
    ".yaml",
    ".html",
    ".js",
    ".css",
    ".gdshader",
    ".py",
}

FORBIDDEN_FILE_SUFFIXES = {
    ".p12",
    ".pfx",
    ".mobileprovision",
    ".keystore",
    ".jks",
}

SECRET_PATTERNS = {
    "OpenAI API key": re.compile(r"\bsk-(?:proj-)?[A-Za-z0-9_-]{20,}\b"),
    "GitHub token": re.compile(r"\b(?:ghp|github_pat)_[A-Za-z0-9_]{20,}\b"),
    "Google API key": re.compile(r"\bAIza[0-9A-Za-z_-]{20,}\b"),
    "AWS access key": re.compile(r"\bAKIA[0-9A-Z]{16}\b"),
    "private key block": re.compile(r"-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----"),
}

ABSOLUTE_PATH_PATTERNS = {
    "Windows user path": re.compile(r"[A-Za-z]:\\Users\\[^\\\s]+\\"),
    "macOS user path": re.compile(r"/Users/[^/\s]+/"),
    "Linux home path": re.compile(r"/home/[^/\s]+/"),
}

PII_PROPERTY_PATTERNS = {
    "analytics email property": re.compile(r"[\"'](?:email|e_mail)[\"']\s*[:=]"),
    "analytics precise location property": re.compile(
        r"[\"'](?:precise_gps|gps_lat|gps_lon|latitude|longitude|address)[\"']\s*[:=]"
    ),
}

ALLOWED_ABSOLUTE_PATH_FILES = {
    # This audit contains the generic path-detection regexes themselves, so only
    # its own source is exempt from this single check. Secrets/signing-file checks
    # still apply to it like every other repository file.
    "tools/release_readiness_audit.py",
}


def iter_repo_files():
    for path in ROOT.rglob("*"):
        if not path.is_file():
            continue
        if any(part in SKIP_DIRS for part in path.relative_to(ROOT).parts):
            continue
        yield path


def rel(path: Path) -> str:
    return path.relative_to(ROOT).as_posix()


def read_text(path: Path) -> str | None:
    if path.suffix.lower() not in TEXT_SUFFIXES and path.name not in {"VERSION", ".gitignore"}:
        return None
    try:
        return path.read_text(encoding="utf-8")
    except UnicodeDecodeError:
        return None


def main() -> int:
    failures: list[str] = []
    warnings: list[str] = []

    for path in iter_repo_files():
        relative = rel(path)
        suffix = path.suffix.lower()

        if suffix in FORBIDDEN_FILE_SUFFIXES:
            failures.append(f"forbidden signing/credential file tracked: {relative}")

        text = read_text(path)
        if text is None:
            continue

        for label, pattern in SECRET_PATTERNS.items():
            if pattern.search(text):
                failures.append(f"{label} pattern detected in {relative}")

        if relative not in ALLOWED_ABSOLUTE_PATH_FILES:
            for label, pattern in ABSOLUTE_PATH_PATTERNS.items():
                if pattern.search(text):
                    failures.append(f"{label} detected in {relative}")

        # Only scan runtime analytics source for disallowed PII property names.
        if relative.startswith("analytics/") and suffix == ".gd":
            for label, pattern in PII_PROPERTY_PATTERNS.items():
                if pattern.search(text):
                    failures.append(f"{label} detected in {relative}")

        if suffix in {".gd", ".tscn", ".tres", ".gdshader"}:
            for marker in ("TODO", "FIXME", "PLACEHOLDER"):
                if marker in text:
                    warnings.append(f"runtime marker {marker} remains in {relative}")

    if failures:
        print("RELEASE_READINESS_FAILED")
        for item in failures:
            print(f"ERROR: {item}")
        if warnings:
            for item in warnings:
                print(f"WARN: {item}")
        return 1

    print("RELEASE_READINESS_OK")
    if warnings:
        print("Non-blocking markers to review before RC:")
        for item in warnings:
            print(f"WARN: {item}")
    else:
        print("No runtime TODO/FIXME/PLACEHOLDER markers detected.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
