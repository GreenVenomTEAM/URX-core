#!/usr/bin/env python3
"""Apply a minimal source-compatibility rename to Alderis for the iOS 18 SDK.

UIKit's iOS 18 SDK adds UIViewController.tab (UITab?). Alderis already
declares a property with the same name but a different type, which is an
invalid override. Rename only Alderis's private implementation property.
"""
from pathlib import Path
import sys

if len(sys.argv) != 2:
    raise SystemExit("usage: patch-alderis-ios18.py <ColorPickerInnerViewController.swift>")

path = Path(sys.argv[1])
if not path.is_file():
    raise SystemExit(f"Alderis source file not found: {path}")

source = path.read_text()
old_decl = "var tab: ColorPickerTab {"
new_decl = "var selectedColorPickerTab: ColorPickerTab {"
old_use = "\t\ttab = configuration.initialTab"
new_use = "\t\tselectedColorPickerTab = configuration.initialTab"

if new_decl in source and new_use in source:
    print("Alderis iOS 18 compatibility patch already applied.")
    raise SystemExit(0)

if source.count(old_decl) != 1 or source.count(old_use) != 1:
    raise SystemExit("Unexpected Alderis source layout; refusing to apply an unsafe patch.")

source = source.replace(old_decl, new_decl, 1).replace(old_use, new_use, 1)
path.write_text(source)
print("Patched Alderis ColorPickerInnerViewController.tab name for UIKit iOS 18 compatibility.")
