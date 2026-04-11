#!/bin/bash
set -euo pipefail

PBXPROJ="Hatoko.xcodeproj/project.pbxproj"

echo "=== Injecting Package Traits ==="

# Check that pbxproj exists
if [ ! -f "$PBXPROJ" ]; then
  echo "ERROR: $PBXPROJ not found. Run 'mint run xcodegen generate' first."
  exit 1
fi

# Check if traits already injected for AzooKeyKanaKanjiConverter
if grep -q 'traits = (Zenzai)' "$PBXPROJ"; then
  echo "Traits already injected for AzooKeyKanaKanjiConverter. Skipping."
  exit 0
fi

echo "Adding traits = (Zenzai) to AzooKeyKanaKanjiConverter package reference..."

# Use awk to find the AzooKeyKanaKanjiConverter XCRemoteSwiftPackageReference block
# definition (the line ending with "= {") and insert traits before its closing };
awk '
  /XCRemoteSwiftPackageReference "AzooKeyKanaKanjiConverter".*= \{/ {
    in_block = 1
    depth = 0
  }
  in_block {
    # Count braces to track nesting depth
    for (i = 1; i <= length($0); i++) {
      c = substr($0, i, 1)
      if (c == "{") depth++
      if (c == "}") depth--
    }
    # When depth returns to 0, we found the closing }; of the outer block
    if (depth == 0) {
      # Insert traits line before the closing };
      match($0, /^[[:space:]]*/)
      indent = substr($0, RSTART, RLENGTH)
      printf "%s\ttraits = (Zenzai);\n", indent
      in_block = 0
    }
  }
  { print }
' "$PBXPROJ" > "${PBXPROJ}.tmp"

mv "${PBXPROJ}.tmp" "$PBXPROJ"

echo "Done. Traits injected successfully."
