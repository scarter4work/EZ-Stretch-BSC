#!/bin/bash
# sign.sh - Sign EZ Stretch BSC scripts using PixInsight
#
# Usage: ./tools/sign.sh
#
# Requires PixInsight to be running and password in /tmp/.pi_codesign_pass

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "Signing EZ Stretch BSC scripts..."
PixInsight --execute="$SCRIPT_DIR/CLICodeSign.js"

# Verify signatures were updated
echo ""
echo "Checking signatures..."
if grep -q "Signature" "$PROJECT_DIR/repository/updates.xri"; then
    echo "  updates.xri: SIGNED"
else
    echo "  updates.xri: NOT SIGNED"
    exit 1
fi

for script in EZStretch LuptonRGB RNC-ColorStretch PhotometricStretch; do
    if [ "$script" = "EZStretch" ]; then
        xsgn="$PROJECT_DIR/src/scripts/EZ Stretch BSC/$script.xsgn"
    else
        xsgn="$PROJECT_DIR/src/scripts/EZ Stretch BSC/$script/$script.xsgn"
    fi

    if [ -f "$xsgn" ]; then
        ts=$(grep -oP 'Timestamp>\K[^<]+' "$xsgn" 2>/dev/null || echo "unknown")
        echo "  $script.xsgn: $ts"
    else
        echo "  $script.xsgn: NOT FOUND"
    fi
done

echo ""
echo "Done."
