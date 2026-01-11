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
import zipfile, hashlib, os

scripts = "$SCRIPTS"
repo = "$REPO"

# Package definitions: (name, version, files_or_dir)
# If files_or_dir is a list, use explicit files
# If files_or_dir is None, include entire subdirectory

packages = {
    "EZStretch": {
        "version": "1.0.5",
        "files": [
            ("EZStretch.js", "EZStretch.js"),
            ("EZStretch.xsgn", "EZStretch.xsgn"),
        ]
    },
    "LuptonRGB": {
        "version": "1.0.14",
        "subdir": "LuptonRGB"
    },
    "RNC-ColorStretch": {
        "version": "1.0.11",
        "subdir": "RNC-ColorStretch"
    },
    "PhotometricStretch": {
        "version": "1.0.23",
        "subdir": "PhotometricStretch"
    },
}

results = []

for name, config in packages.items():
    version = config["version"]
    zipname = f"{repo}/{name}_v{version}.zip"

    # Remove old versions of this package
    import glob
    for old in glob.glob(f"{repo}/{name}_v*.zip"):
        os.remove(old)

    with zipfile.ZipFile(zipname, 'w', zipfile.ZIP_DEFLATED) as zf:
        if "files" in config:
            # Explicit file list
            for src, dst in config["files"]:
                srcpath = f"{scripts}/{src}"
                if os.path.exists(srcpath):
                    zf.write(srcpath, dst)
        elif "subdir" in config:
            # Include entire subdirectory
            base = f"{scripts}/{config['subdir']}"
            for root, dirs, filenames in os.walk(base):
                for f in filenames:
                    src = os.path.join(root, f)
                    dst = os.path.relpath(src, base)
                    zf.write(src, dst)

    with open(zipname, 'rb') as f:
        sha1 = hashlib.sha1(f.read()).hexdigest()

    results.append((name, version, sha1))
    print(f"{name}_v{version}.zip: {sha1}")

print()
print("Update repository/updates.xri with these SHA1 hashes:")
for name, version, sha1 in results:
    print(f'  {name}: sha1="{sha1}"')
EOF

echo ""
echo "Done. Now update updates.xri and run ./tools/sign.sh again."
