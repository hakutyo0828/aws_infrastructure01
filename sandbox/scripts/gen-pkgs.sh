#!/usr/bin/env bash
#
# gen-pkgs.sh: Generate a pkgs.txt (for yum-upgrade.sh) from available updates
#
# 出力フォーマット: "name version-release.arch"（yum-pin.sh と互換）
# モード:
#   1) 既定（check-updateベース）: yum check-update を解析して列挙
#   2) --repo: repoquery で正確な版を列挙
#   3) --security: （--repo時のみ）セキュリティ更新に限定
#
set -euo pipefail

usage() {
  cat <<'EOF'
Generate pkgs.txt for yum-upgrade.sh

Usage:
  gen-pkgs.sh [-o pkgs.txt] [--pin [--allow-erasing] [-l] [--dry-run]]
  gen-pkgs.sh --repo [--security] [-o pkgs.txt] [--pin ...]
  gen-pkgs.sh -i check-update.txt [-o pkgs.txt] [--pin ...]

Options:
  --repo                Use repoquery instead of yum check-update
  --security            Only include security updates (with --repo)
  -i, --input FILE      Use an existing 'yum check-update' output file (default: run command)
  -o, --output FILE     Output file (default: stdout)
  --pin                 Immediately run yum-upgrade.sh with the generated list
      --allow-erasing   Forward to yum-upgrade.sh (allow dependency replacement)
  -l, --lock            Forward to yum-upgrade.sh (versionlock after install)
      --dry-run         Forward to yum-upgrade.sh (no changes)
  -h, --help            Show this help

Notes:
  - Default mode parses 'yum check-update' for simplicity.
  - --repo mode uses repoquery (yum-utils) to get exact versions/releases.
  - Output lines look like:  curl 7.55.1-8.amzn2.0.1.x86_64
  - This file can be consumed by:  yum-upgrade.sh -f pkgs.txt

Examples:
  # From yum check-update (default)
  gen-pkgs.sh -o /tmp/pkgs.txt

  # Security-only updates
  gen-pkgs.sh --security -o /tmp/pkgs.txt

  # From 'yum check-update' output file
  yum check-update > /tmp/cu.txt || true
  gen-pkgs.sh --from-check-update -i /tmp/cu.txt -o /tmp/pkgs.txt
  
  # Generate and immediately apply with yum-upgrade.sh
  gen-pkgs.sh -o /tmp/pkgs.txt --pin --allow-erasing -l
EOF
}

# ------------------------
# Args
# ------------------------
OUT=""
MODE="check"    # check | repo
INFILE=""
SECURITY_ONLY=0
RUN_PIN=0
PIN_ALLOW_ERASING=0
PIN_LOCK=0
PIN_DRYRUN=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo) MODE="repo"; shift ;;
    --security) SECURITY_ONLY=1; shift ;;
    -i|--input) INFILE="${2:-}"; shift 2 ;;
    -o|--output) OUT="${2:-}"; shift 2 ;;
    --pin) RUN_PIN=1; shift ;;
    --allow-erasing) PIN_ALLOW_ERASING=1; shift ;;
    -l|--lock) PIN_LOCK=1; shift ;;
    --dry-run) PIN_DRYRUN=1; shift ;;
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

# 生成直後に yum-pin.sh を呼び出す（--pin）
if [[ $RUN_PIN -eq 1 ]]; then
  # 決定した出力の場所（ファイル or 一時ファイル）を特定
  PKGS_FILE="$OUT"
  if [[ -z "$PKGS_FILE" ]]; then
    PKGS_FILE="$(mktemp /tmp/pkgs.XXXXXX.txt)"
    # 直前と同じ出力をもう一度作成して保存
    if [[ "$MODE" == "repo" ]]; then
      if [[ $SECURITY_ONLY -eq 1 ]]; then
        printf '%s\n' "$all_updates" | filter_to_security | sort -u > "$PKGS_FILE"
      else
        printf '%s\n' "$all_updates" | sort -u > "$PKGS_FILE"
      fi
    else
      if [[ -n "$INFILE" ]]; then
        cat "$INFILE" | parse_check_update_stream > "$PKGS_FILE"
      else
        $YUM check-update -q || true | parse_check_update_stream > "$PKGS_FILE"
      fi
    fi
  fi

  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  PIN_SH="$SCRIPT_DIR/yum-upgrade.sh"
  if [[ ! -x "$PIN_SH" ]]; then
    echo "yum-upgrade.sh not found or not executable at: $PIN_SH" >&2
    exit 3
  fi

  PIN_ARGS=( -f "$PKGS_FILE" )
  [[ $PIN_ALLOW_ERASING -eq 1 ]] && PIN_ARGS+=( --allow-erasing )
  [[ $PIN_LOCK -eq 1 ]] && PIN_ARGS+=( --lock )
  [[ $PIN_DRYRUN -eq 1 ]] && PIN_ARGS+=( --dry-run )

  echo "Running: $PIN_SH ${PIN_ARGS[*]}"
  bash "$PIN_SH" "${PIN_ARGS[@]}"
fi
