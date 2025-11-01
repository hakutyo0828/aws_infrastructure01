#!/usr/bin/env bash
#
# gen-pkgs.sh: Generate a pkgs.txt (for yum-pin.sh) from available updates
#
# 出力フォーマット: "name version-release.arch"（yum-pin.sh と互換）
# モード:
#   1) 既定（repoqueryベース）: 利用可能な更新を正確な版で列挙
#   2) --security: セキュリティ更新のみ（updateinfoと突合）
#   3) --from-check-update: yum check-update の出力を整形して列挙
#
set -euo pipefail

usage() {
  cat <<'EOF'
Generate pkgs.txt for yum-pin.sh

Usage:
  gen-pkgs.sh [-o pkgs.txt]
  gen-pkgs.sh --security [-o pkgs.txt]
  gen-pkgs.sh --from-check-update [-i check-update.txt] [-o pkgs.txt]

Options:
  --security            Only include security updates (uses 'yum updateinfo list security')
  --from-check-update   Parse 'yum check-update' (from stdin or -i file)
  -i, --input FILE      Input file for --from-check-update (omit to run command)
  -o, --output FILE     Output file (default: stdout)
  -h, --help            Show this help

Notes:
  - Default mode uses repoquery (yum-utils) to get exact versions/releases.
  - Output lines look like:  curl 7.55.1-8.amzn2.0.1.x86_64
  - This file can be consumed by:  yum-pin.sh -f pkgs.txt

Examples:
  # All available updates to pkgs.txt
  gen-pkgs.sh -o /tmp/pkgs.txt

  # Security-only updates
  gen-pkgs.sh --security -o /tmp/pkgs.txt

  # From 'yum check-update' output file
  yum check-update > /tmp/cu.txt || true
  gen-pkgs.sh --from-check-update -i /tmp/cu.txt -o /tmp/pkgs.txt
EOF
}

# ------------------------
# Args
# ------------------------
OUT=""
MODE="repo"    # repo | check
INFILE=""
SECURITY_ONLY=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --from-check-update) MODE="check"; shift ;;
    --security) SECURITY_ONLY=1; shift ;;
    -i|--input) INFILE="${2:-}"; shift 2 ;;
    -o|--output) OUT="${2:-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown arg: $1" >&2; usage; exit 1 ;;
  esac
done

# ------------------------
# Helpers
# ------------------------
SUDO=""; [[ $EUID -ne 0 ]] && SUDO="sudo"
YUM="$SUDO yum"

emit() {
  # Emit stdin to file or stdout
  if [[ -n "$OUT" ]]; then
    tee "$OUT"
  else
    cat
  fi
}

ensure_tools() {
  # repoquery を使うため yum-utils を導入（既にあれば何もしない）
  $YUM -y -q install yum-utils >/dev/null 2>&1 || true
}

list_updates_repoquery() {
  # すべての更新候補を name version-release.arch で出力
  repoquery --pkgnarrow=updates -a --qf '%{name} %{version}-%{release}.%{arch}' || true
}

list_security_names() {
  # security更新のパッケージ名を抽出（name または name.arch の末尾から名前部を取得）
  $YUM updateinfo list security -q 2>/dev/null | awk '{print $NF}' | sed 's/\.[^.]*$//' | sort -u || true
}

filter_to_security() {
  # 入力（全更新リスト）を security 名称にフィルタ
  local names
  names=$(list_security_names)
  if [[ -z "$names" ]]; then
    echo "No security updates detected by yum updateinfo." >&2
    return 0
  fi
  awk -v names="$names" 'BEGIN{ split(names,a,"\n"); for(i in a){ if(a[i]!="") s[a[i]]=1 } } { if($1 in s) print }'
}

parse_check_update_stream() {
  # yum check-update の出力から name version-release.arch を抽出
  # 想定行: "name.arch  version-release  repo"
  awk 'NF==3 && $1 ~ /\./ {
    name=$1
    arch=substr(name, match(name,/[^.]+$/))
    sub("\\." arch "$", "", name)
    ver=$2
    printf "%s %s.%s\n", name, ver, arch
  }' | sort -u
}

# ------------------------
# Main
# ------------------------
ensure_tools

if [[ "$MODE" == "repo" ]]; then
  all_updates=$(list_updates_repoquery)
  if [[ -z "$all_updates" ]]; then
    echo "No updates found (repoquery returned empty)." >&2
    exit 0
  fi
  if [[ $SECURITY_ONLY -eq 1 ]]; then
    printf '%s\n' "$all_updates" | filter_to_security | sort -u | emit
  else
    printf '%s\n' "$all_updates" | sort -u | emit
  fi
else
  # MODE=check : 入力ファイル or コマンド実行
  if [[ -n "$INFILE" ]]; then
    cat "$INFILE" | parse_check_update_stream | emit
  else
    $YUM check-update -q || true | parse_check_update_stream | emit
  fi
fi
