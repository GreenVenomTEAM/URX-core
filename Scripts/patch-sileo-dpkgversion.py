#!/usr/bin/env python3
"""Add the standard type headers omitted by upstream Sileo's dpkgversion.h."""
from pathlib import Path
import stat
import sys

if len(sys.argv) != 2:
    raise SystemExit("usage: patch-sileo-dpkgversion.py <dpkgversion.h>")

path = Path(sys.argv[1])
if not path.is_file():
    raise SystemExit(f"Sileo dpkgversion.h not found: {path}")

source = path.read_text()
marker = "#include <stdio.h>"
addition = "#include <sys/types.h>\n#include <stdint.h>"
if addition in source:
    print("Sileo dpkgversion.h type-header patch already applied.")
    raise SystemExit(0)
if source.count(marker) != 1:
    raise SystemExit("Unexpected Sileo dpkgversion.h layout; refusing to patch.")

source = source.replace(marker, marker + "\n" + addition, 1)
path.chmod(path.stat().st_mode | stat.S_IWUSR)
path.write_text(source)
print("Patched Sileo dpkgversion.h with sys/types.h and stdint.h.")
