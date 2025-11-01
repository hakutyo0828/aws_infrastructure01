#!/usr/bin/env bash
# yum-upgrade-min.sh : pkgs.txt を読み取り、指定 NEVRA をインストール（更新）します
# 入力形式: 行ごとに「name version-release.arch」

set -euo pipefail

usage() { echo "Usage: yum-upgrade-min.sh -f pkgs.txt" >&2; }

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

while IFS= read -r line || [[ -n "$line" ]]; do
  line="${line%%#*}"; line="$(echo "$line" | xargs || true)"
  [[ -z "$line" ]] && continue
  name="$(awk '{print $1}' <<<"$line")"
  verrelarch="$(awk '{print $2}' <<<"$line")"
  [[ -z "$name" || -z "$verrelarch" ]] && { echo "Invalid line: $line" >&2; exit 1; }
  NEVRAS+=("${name}-${verrelarch}")
done < "$FILE"

echo "Upgrading:"
printf '  %s\n' "${NEVRAS[@]}"

set -x
$YUM -y upgrade "${NEVRAS[@]}"
set +x
echo "Done."
