# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

EZ Stretch BSC is a collection of PixInsight JavaScript Runtime (PJSR) scripts for astrophotography image stretching:

- **PhotometricStretch** - Physics-based asinh stretch with auto hardware detection
- **LuptonRGB** - Lupton et al. color-preserving asinh stretch
- **RNC-ColorStretch** - Roger Clark's power stretch with color recovery

## Repository Structure

```
EZ-Stretch-BSC/
├── src/scripts/EZ Stretch BSC/    # PixInsight scripts (this is the install path)
│   ├── PhotometricStretch/
│   │   ├── PhotometricStretch.js
│   │   ├── lib/                   # Module dependencies
│   │   └── data/                  # JSON databases (sensors, cameras, filters)
│   ├── LuptonRGB/
│   │   └── LuptonRGB.js
│   └── RNC-ColorStretch/
│       └── RNC-ColorStretch.js
├── repository/                     # PixInsight update repository
│   └── updates.xri                 # Update manifest
└── docs/                          # Requirements and design docs
```

## Git Workflow

Push directly to main without asking - this is a PixInsight plugin suite, not critical infrastructure.

## Release Process

When making changes to a script:

1. Update `#define VERSION` in the main .js file
2. Sign scripts: `./tools/sign.sh` (runs PixInsight headless, needs password in /tmp/.pi_codesign_pass)
3. Build packages: `./tools/build-packages.sh` (creates zips with signed scripts, outputs SHA1 hashes)
4. Update `repository/updates.xri` with new version, SHA1, and changelog
5. Re-sign: `./tools/sign.sh` (signs the updated updates.xri)
6. Install locally: `./tools/install-local.sh` (copies to ~/.PixInsight/src/scripts)
7. Commit and push

### Tools

- `tools/sign.sh` - Signs all scripts and updates.xri using PixInsight headless mode (`-n=9 --automation-mode --force-exit`)
- `tools/build-packages.sh` - Builds zip packages including .xsgn signature files
- `tools/install-local.sh` - Installs to user's PixInsight directory (no sudo needed)
- `tools/CLICodeSign.js` - PJSR script that performs actual signing via Security API

### Signing Requirements

- Password file: `/tmp/.pi_codesign_pass`
- Keys file: `/home/scarter4work/projects/keys/scarter4work_keys.xssk`
- PixInsight must be installed (but doesn't need to be running)

## PJSR-Specific Patterns

### Reading FITS Keywords
```javascript
const keywords = view.window.keywords;
function getFITSValue(view, name) {
  for (let i = 0; i < keywords.length; i++) {
    if (keywords[i].name === name)
      return keywords[i].value.trim().replace(/^'|'$/g, '');
  }
  return null;
}
```

### Pixel Access
```javascript
const image = view.image;
const samples = new Float64Array(image.width * image.height);
image.getSamples(samples, new Rect(0, 0, image.width, image.height), channelIndex);
// Modify samples...
image.setSamples(samples, new Rect(0, 0, image.width, image.height), channelIndex);
```

### Undo Support
```javascript
view.beginProcess();
try {
  // ... modify image ...
} finally {
  view.endProcess();
}
```

### UI Notes
- Use `Control.repaint()` for immediate redraws, not `update()` which only schedules
- Preview controls need throttling on slider updates to stay responsive
- PreviewControl pattern: Use Frame + ScrollBox + VectorGraphics

## Script-Specific Notes

### PhotometricStretch
- Uses modular architecture with lib/ dependencies
- Hardware matching uses fuzzy Levenshtein matching
- FITS keywords tried in order: INSTRUME > CAMERA > DETECTOR > CCD_NAME

### LuptonRGB
- Single-file script with embedded classes
- Clipping modes: Preserve Color (Lupton), Hard Clip, Rescale to Max

### RNC-ColorStretch
- Implements 6 color ratios for color recovery
- S-curve variants: SC1, SC2, SC3, SC4
