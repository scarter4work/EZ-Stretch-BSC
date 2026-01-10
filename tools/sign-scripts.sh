#!/bin/bash
# ============================================================================
# sign-scripts.sh - Sign all EZ Stretch BSC scripts
# ============================================================================
#
# Usage:
#   ./tools/sign-scripts.sh <keys_file> <password>
#
# Example:
#   ./tools/sign-scripts.sh ~/my-signing-keys.xssk MySecretPassword
#
# ============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Default keys file location
DEFAULT_KEYS="$HOME/projects/keys/scarter4work_keys.xssk"

# Check arguments
if [ $# -lt 1 ]; then
    echo "Usage: $0 <password> [keys_file]"
    echo "Example: $0 MySecretPassword"
    echo "         $0 MySecretPassword ~/my-signing-keys.xssk"
    echo ""
    echo "Default keys file: $DEFAULT_KEYS"
    exit 1
fi

PASSWORD="$1"
KEYS_FILE="${2:-$DEFAULT_KEYS}"

# Check if keys file exists
if [ ! -f "$KEYS_FILE" ]; then
    echo "Error: Keys file not found: $KEYS_FILE"
    exit 1
fi

# Convert to absolute path
KEYS_FILE="$(realpath "$KEYS_FILE")"

# Define scripts to sign
SCRIPTS=(
    "$PROJECT_DIR/src/scripts/EZ Stretch BSC/EZStretch.js"
    "$PROJECT_DIR/src/scripts/EZ Stretch BSC/LuptonRGB/LuptonRGB.js"
    "$PROJECT_DIR/src/scripts/EZ Stretch BSC/RNC-ColorStretch/RNC-ColorStretch.js"
    "$PROJECT_DIR/src/scripts/EZ Stretch BSC/PhotometricStretch/PhotometricStretch.js"
    "$PROJECT_DIR/repository/updates.xri"
)

# Build semicolon-separated file list
FILE_LIST=""
for script in "${SCRIPTS[@]}"; do
    if [ -f "$script" ]; then
        if [ -n "$FILE_LIST" ]; then
            FILE_LIST="$FILE_LIST;"
        fi
        FILE_LIST="$FILE_LIST$script"
    else
        echo "Warning: File not found: $script"
    fi
done

echo "============================================"
echo "EZ Stretch BSC - Code Signing"
echo "============================================"
echo ""
echo "Keys file: $KEYS_FILE"
echo "Scripts to sign: ${#SCRIPTS[@]}"
echo ""

# Find PixInsight executable
if [ -x "/opt/PixInsight/bin/PixInsight" ]; then
    PI_EXE="/opt/PixInsight/bin/PixInsight"
elif [ -x "/usr/local/PixInsight/bin/PixInsight" ]; then
    PI_EXE="/usr/local/PixInsight/bin/PixInsight"
elif [ -x "$HOME/PixInsight/bin/PixInsight" ]; then
    PI_EXE="$HOME/PixInsight/bin/PixInsight"
else
    echo "Error: PixInsight executable not found"
    echo "Please set PI_EXE environment variable to your PixInsight path"
    exit 1
fi

echo "Using PixInsight: $PI_EXE"
echo ""

# Run the signing script
"$PI_EXE" -n --automation-mode \
    -r="$SCRIPT_DIR/CLICodeSign.js,keys=$KEYS_FILE,pass=$PASSWORD,files=$FILE_LIST" \
    --force-exit

echo ""
echo "Done!"
