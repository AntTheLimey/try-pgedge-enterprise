#!/usr/bin/env python3
"""Validate package-catalog/catalog.json structure."""
import json
import os
import sys

CATALOG = "package-catalog/catalog.json"

if not os.path.exists(CATALOG):
    print("catalog.json not yet created — skipping validation")
    sys.exit(0)

with open(CATALOG) as f:
    d = json.load(f)

errors = []

for key in ("categories", "platforms", "meta_packages", "pg_versions"):
    if key not in d:
        errors.append(f"missing {key}")

for cat in d.get("categories", []):
    for pkg in cat.get("packages", []):
        if not pkg.get("name"):
            errors.append(f"package missing name in {cat['name']}")
        if not pkg.get("pg_versions"):
            errors.append(f"{pkg.get('name', '?')} missing pg_versions")

for key, plat in d.get("platforms", {}).items():
    if not plat.get("install_pattern"):
        errors.append(f"{key} missing install_pattern")

if errors:
    print("Validation errors:")
    for e in errors:
        print(f"  - {e}")
    sys.exit(1)

cats = len(d["categories"])
pkgs = sum(len(c["packages"]) for c in d["categories"])
plats = len(d["platforms"])
print(f"✓ catalog.json valid: {cats} categories, {pkgs} packages, {plats} platforms")
