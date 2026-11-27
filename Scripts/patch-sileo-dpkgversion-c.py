#!/usr/bin/env python3
"""Avoid an iOS SDK link to memrchr emitted while optimizing dpkgversion.c."""
from pathlib import Path
import stat
import sys

if len(sys.argv) != 2:
    raise SystemExit("usage: patch-sileo-dpkgversion-c.py <dpkgversion.c>")

path = Path(sys.argv[1])
if not path.is_file():
    raise SystemExit(f"Sileo dpkgversion.c not found: {path}")

source = path.read_text()
old = 'if (!(isdigit(character) || isalpha(character) || strrchr(".-+~:", character))) {'
new = 'if (!(isdigit(character) || isalpha(character) || character == \'.\' || character == \'-\' || character == \'+\' || character == \'~\' || character == \':\')) {'
# The explicit comparisons prevent Clang from lowering this tiny lookup to
# memrchr, which is not provided by the iOS SDK's libc.
if new in source:
    print("Sileo dpkgversion.c portability patch already applied.")
    raise SystemExit(0)
if source.count(old) != 1:
    raise SystemExit("Unexpected Sileo dpkgversion.c layout; refusing to patch.")

path.chmod(path.stat().st_mode | stat.S_IWUSR)
path.write_text(source.replace(old, new, 1))
print("Patched Sileo dpkgversion.c to avoid the unavailable memrchr symbol.")
