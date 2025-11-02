#!/usr/bin/env bash
# install.sh: Install helper to run scripts without prefixing bash
# Copies scripts to /usr/local/bin and sets execute permission.

set -euo pipefail

DEST=${1:-/usr/local/bin}
SCRIPTS_DIR=$(cd "$(dirname "$0")" && pwd)

echo "Installing to: $DEST"
sudo mkdir -p "$DEST"

for f in gen-pkgs.sh yum-upgrade.sh; do
  src="$SCRIPTS_DIR/$f"
  if [[ ! -f "$src" ]]; then
    echo "Skip missing: $src" >&2
    continue
  fi
  # Normalize line endings just in case the file has CRLF
  sudo sed -i 's/\r$//' "$src" || true
  sudo install -m 0755 "$src" "$DEST/$f"
  echo "Installed: $DEST/$f"
done

echo "Done. Ensure $DEST is in your PATH. Try: gen-pkgs.sh --help (if implemented)"

