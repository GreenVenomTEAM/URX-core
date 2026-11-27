#!/usr/bin/env python3
"""Make the upstream Sileo storyboard safe to embed in the URXCore app target."""
from pathlib import Path
import sys

source = Path("Vendor/Sileo/Sileo/Base.lproj/Main.storyboard")
destination = source.with_name("URXSileo.storyboard")

if not source.is_file():
    raise SystemExit(f"Upstream Sileo storyboard not found: {source}")
if destination.exists():
    raise SystemExit(f"Refusing to overwrite existing storyboard: {destination}")

xml = source.read_text()
old_module = 'customModule="Sileo"'
new_module = 'customModule="URXCore"'
count = xml.count(old_module)
if count == 0:
    raise SystemExit("Expected upstream Sileo module declarations were not found.")
if 'customModule="URXCore"' in xml:
    raise SystemExit("Storyboard appears partially patched; refusing an ambiguous rewrite.")

xml = xml.replace(old_module, new_module)
destination.write_text(xml)
source.unlink()

print(f"Renamed storyboard to {destination.name} and updated {count} custom class module declarations.")
