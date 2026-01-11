#!/bin/bash
# build-packages.sh - Build repository zip packages with signed scripts
#
# Usage: ./tools/build-packages.sh
#
# Run ./tools/sign.sh first to sign all scripts!

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
SCRIPTS="$PROJECT_DIR/src/scripts/EZ Stretch BSC"
REPO="$PROJECT_DIR/repository"

echo "Building repository packages..."

python3 << EOF
import zipfile, hashlib, os, glob

scripts = "$SCRIPTS"
repo = "$REPO"

# Only EZ Stretch - the unified script
packages = {
    "EZStretch": {
        "version": "1.0.6",
        "files": [
            ("EZStretch.js", "EZStretch.js"),
            ("EZStretch.xsgn", "EZStretch.xsgn"),
        ]
    },
}

results = []

for name, config in packages.items():
    version = config["version"]
    zipname = f"{repo}/{name}_v{version}.zip"

    # Remove old versions of this package
    for old in glob.glob(f"{repo}/{name}_v*.zip"):
        os.remove(old)

    with zipfile.ZipFile(zipname, 'w', zipfile.ZIP_DEFLATED) as zf:
        for src, dst in config["files"]:
            srcpath = f"{scripts}/{src}"
            if os.path.exists(srcpath):
                zf.write(srcpath, dst)

    with open(zipname, 'rb') as f:
        sha1 = hashlib.sha1(f.read()).hexdigest()

    results.append((name, version, sha1))
    print(f"{name}_v{version}.zip: {sha1}")

print()
print("Update repository/updates.xri with this SHA1 hash:")
for name, version, sha1 in results:
    print(f'  {name}: sha1="{sha1}"')
EOF

echo ""
echo "Done. Now update updates.xri and run ./tools/sign.sh again."
