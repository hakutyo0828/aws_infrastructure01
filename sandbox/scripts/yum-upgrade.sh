#!/usr/bin/env bash
# yum-upgrade.sh : pkgs.txt を読み取り、指定 NEVRA をアップグレードします
# 入力形式: 行ごとに「name version-release.arch」
# 使い方:
#   yum-upgrade.sh -f /tmp/YYYYMMDD/pkgs.txt
# 出力:
#   - /tmp/YYYYMMDD/pkgs_applied.txt    適用対象の NEVRA 一覧
#   - /tmp/YYYYMMDD/installed_after.txt 適用後のインストールバージョン 一覧

set -euo pipefail

usage() { echo "Usage: yum-upgrade.sh -f pkgs.txt" >&2; }

FILE=""
while [[ $# -gt 0 ]]; do
  case "${1:-}" in
    -f|--file) FILE="${2:-}"; shift 2;;
    -h|--help) usage; exit 0;;
    *) echo "Unknown arg: $1" >&2; usage; exit 1;;
  esac
done

[[ -n "${FILE}" && -f "${FILE}" ]] || { echo "File not found: ${FILE}" >&2; exit 1; }

YUM=${YUM:-yum}
NEVRAS=()
NAMES=()

while IFS= read -r line || [[ -n "$line" ]]; do
  line="${line%%#*}"; line="$(echo "$line" | xargs || true)"
  [[ -z "$line" ]] && continue
  name="$(awk '{print $1}' <<<"$line")"
  verrelarch="$(awk '{print $2}' <<<"$line")"
  [[ -z "$name" || -z "$verrelarch" ]] && { echo "Invalid line: $line" >&2; exit 1; }
  NEVRAS+=("${name}-${verrelarch}")
  NAMES+=("$name")
done < "$FILE"

# 出力ディレクトリ（当日日付）
OUT_DIR="/tmp/$(date +%Y%m%d)"
mkdir -p "$OUT_DIR"
PKGS_APPLIED="$OUT_DIR/pkgs_applied.txt"
INST_AFTER="$OUT_DIR/installed_after.txt"

echo "Upgrading:"
printf '  %s\n' "${NEVRAS[@]}"
printf '%s\n' "${NEVRAS[@]}" > "$PKGS_APPLIED"

set -x
$YUM -y upgrade "${NEVRAS[@]}"
set +x

# 適用後のインストールバージョン 一覧
: > "$INST_AFTER"
for pname in "${NAMES[@]}"; do
  if rpm -q --qf '%{NAME} %{VERSION}-%{RELEASE}.%{ARCH}\n' "$pname" >/dev/null 2>&1; then
    rpm -q --qf '%{NAME} %{VERSION}-%{RELEASE}.%{ARCH}\n' "$pname" >> "$INST_AFTER"
  else
    echo "$pname not-installed" >> "$INST_AFTER"
  fi
done

echo "[yum-upgrade.sh] Saved: $PKGS_APPLIED" >&2
echo "[yum-upgrade.sh] Installed versions (after): $INST_AFTER" >&2
echo "Done."

