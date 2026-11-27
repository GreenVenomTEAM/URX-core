#!/usr/bin/env python3
"""Make Sileo's ZKSwizzle global dictionary compatible with ARC."""
from pathlib import Path
import stat
import sys

if len(sys.argv) != 2:
    raise SystemExit("usage: patch-sileo-zkswizzle-arc.py <ZKSwizzle.m>")

path = Path(sys.argv[1])
if not path.is_file():
    raise SystemExit(f"Sileo ZKSwizzle.m not found: {path}")

source = path.read_text()
old = "groups = [[NSMutableDictionary dictionary] retain];"
new = "groups = [NSMutableDictionary dictionary];"

if new in source:
    print("Sileo ZKSwizzle ARC patch already applied.")
    raise SystemExit(0)
if source.count(old) != 1:
    raise SystemExit("Unexpected ZKSwizzle.m layout; refusing to patch.")

path.chmod(path.stat().st_mode | stat.S_IWUSR)
path.write_text(source.replace(old, new, 1))
print("Patched Sileo ZKSwizzle global dictionary for ARC.")
