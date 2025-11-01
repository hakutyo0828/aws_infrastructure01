#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: yum-upgrade.sh -f pkgs.txt [-l] [--allow-erasing] [--dry-run]
  -f, --file           Package list file. One per line:
                         name version-release[.arch]
                         or name=version-release[.arch]
  -l, --lock           Add yum versionlock after install
      --allow-erasing  Allow removing/conflicting packages to satisfy request
      --dry-run        Show actions without changing the system

Example (pkgs.txt):
  curl 7.55.1-8.amzn2.0.1.x86_64
  libcurl 7.55.1-8.amzn2.0.1.x86_64
EOF
}

FILE=""
LOCK=0
ALLOW_ERASING=0
DRY_RUN=0

while [[ $# -gt 0 ]]; do
  case "${1:-}" in
    -f|--file) FILE="${2:-}"; shift 2;;
    -l|--lock) LOCK=1; shift;;
    --allow-erasing) ALLOW_ERASING=1; shift;;
    --dry-run) DRY_RUN=1; shift;;
    -h|--help) usage; exit 0;;
    *) echo "Unknown arg: $1" >&2; usage; exit 1;;
  esac
done

[[ -n "${FILE}" && -f "${FILE}" ]] || { echo "File not found: ${FILE}" >&2; exit 1; }

SUDO=""; [[ $EUID -ne 0 ]] && SUDO="sudo"
YUM="$SUDO yum"
NEVRAS=()
NAMES=()
VERS=()

# Prepare repos and tools
$YUM clean all -q || true
$YUM -y -q makecache || true
$YUM -y -q install yum-utils >/dev/null 2>&1 || true

# Parse file
while IFS= read -r raw || [[ -n "$raw" ]]; do
  line="${raw%%#*}"; line="$(echo "$line" | xargs || true)"
  [[ -z "$line" ]] && continue
  if [[ "$line" == *"="* ]]; then
    name="${line%%=*}"
    verrelarch="${line#*=}"
  else
    name="$(echo "$line" | awk '{print $1}')"
    verrelarch="$(echo "$line" | awk '{print $2}')"
  fi
  [[ -z "$name" || -z "$verrelarch" ]] && { echo "Invalid line: $raw" >&2; exit 1; }
  nevr="${name}-${verrelarch}"
  NEVRAS+=("$nevr")
  NAMES+=("$name")
  VERS+=("$verrelarch")
done < "$FILE"

# Validate availability in repos
for i in "${!NAMES[@]}"; do
  n="${NAMES[$i]}"; v="${VERS[$i]}"
  if ! $YUM --showduplicates list "$n" 2>/dev/null | awk '{print $2}' | grep -qx "$v"; then
    echo "Target version not found in repos for $n: $v" >&2
    echo "Hint: yum --showduplicates list $n" >&2
    exit 2
  fi
done

echo "Packages to pin:"
printf '  %s\n' "${NEVRAS[@]}"

if [[ $DRY_RUN -eq 1 ]]; then
  echo "[DRY-RUN] Would run: yum install -y ${NEVRAS[*]} ${ALLOW_ERASING:+--allowerasing}"
  if [[ $LOCK -eq 1 ]]; then
    echo "[DRY-RUN] Would versionlock add: ${NEVRAS[*]} (with wildcard *)"
  fi
  exit 0
fi

set -x
if [[ $ALLOW_ERASING -eq 1 ]]; then
  $YUM -y install --allowerasing "${NEVRAS[@]}"
else
  if ! $YUM -y downgrade "${NEVRAS[@]}"; then
    $YUM -y install "${NEVRAS[@]}"
  fi
fi

if [[ $LOCK -eq 1 ]]; then
  $YUM -y install yum-plugin-versionlock
  for nevr in "${NEVRAS[@]}"; do
    $SUDO yum versionlock add "${nevr}"'*' || true
  done
  $SUDO yum versionlock list || true
fi

for name in "${NAMES[@]}"; do
  rpm -q "$name" || true
done
set +x
echo "Done."
