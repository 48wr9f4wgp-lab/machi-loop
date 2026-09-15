#!/usr/bin/env python3
"""Report whether the local machine is ready for MACHI LOOP native export."""
from __future__ import annotations
import argparse, os, platform, shutil, subprocess, sys
from dataclasses import dataclass
@dataclass
class Check:
    name:str; ok:bool; detail:str; required_for:tuple[str,...]
def command_version(name,args):
    executable=shutil.which(name)
    if executable is None:return False,"not found on PATH"
    try:
        c=subprocess.run([executable,*args],stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True,timeout=8,check=False)
        lines=(c.stdout or "").strip().splitlines(); detail=lines[0] if lines else f"exit={c.returncode}"
        return c.returncode==0,detail
    except (OSError,subprocess.TimeoutExpired) as exc:return False,f"unable to run: {exc}"
def android_checks():
    sdk=os.environ.get("ANDROID_SDK_ROOT") or os.environ.get("ANDROID_HOME")
    j,jd=command_version("java",["-version"]); jc,jcd=command_version("javac",["-version"]); a,ad=command_version("adb",["version"]); s,sd=command_version("sdkmanager",["--version"])
    return [Check("Java runtime",j,jd,("android",)),Check("Java compiler",jc,jcd,("android",)),Check("Android SDK root",bool(sdk),sdk or "ANDROID_SDK_ROOT/ANDROID_HOME not set",("android",)),Check("adb",a,ad,("android",)),Check("sdkmanager",s,sd,())]
def ios_checks():
    system=platform.system(); x,xd=command_version("xcodebuild",["-version"])
    return [Check("macOS host",system=="Darwin",f"host={system}",("ios",)),Check("Xcode",x,xd,("ios",))]
def common_checks():
    g,gd=command_version("godot",["--version"])
    if not g:g,gd=command_version("godot4",["--version"])
    return [Check("Godot",g,gd,("android","ios"))]
def main():
    p=argparse.ArgumentParser(); p.add_argument("--target",choices=("android","ios","all"),default="all"); args=p.parse_args()
    targets={"android","ios"} if args.target=="all" else {args.target}; checks=common_checks()+android_checks()+ios_checks()
    print("MACHI_LOOP_NATIVE_PREFLIGHT"); print(f"host={platform.system()} {platform.release()} architecture={platform.machine()}")
    for c in checks:
        if not (targets.intersection(c.required_for) or not c.required_for):continue
        print(f"[{'OK' if c.ok else 'MISSING'}{' optional' if not c.required_for else ''}] {c.name}: {c.detail}")
    hard=[c for c in checks if c.required_for and targets.intersection(c.required_for) and not c.ok]
    if hard:
        print("PREFLIGHT_NOT_READY")
        for c in hard:print(f"REQUIRED: {c.name}")
        return 1
    print("PREFLIGHT_READY_FOR_TOOLCHAIN_VALIDATION"); print("Note: this does not validate signing, package identifiers, SDK API levels, export templates, or physical-device install."); return 0
if __name__=="__main__":sys.exit(main())
