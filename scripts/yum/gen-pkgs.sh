#!/usr/bin/env bash
# gen-pkgs.sh: yum check-update を実行し、"name version-release.arch" を出力します
# 使い方:
#   bash gen-pkgs.sh                        # 全件
#   bash gen-pkgs.sh -p package.ini         # 指定パッケージのみ（name または name.arch を1行ずつ）
# 出力:
#   - 標準出力: name version-release.arch（後段スクリプト用）
#   - /tmp/YYYYMMDD/check_update_raw.txt
#   - /tmp/YYYYMMDD/pkgs.txt（整形後）
#   - /tmp/YYYYMMDD/installed_before.txt（現在のインストールバージョンの一覧）

set -euo pipefail

PKGFILE=""
if [[ ${1-} =~ ^(-p|--packages)$ ]]; then
  PKGFILE="${2-}"
  shift 2 || true
fi

OUT_DIR="/tmp/$(date +%Y%m%d)"
mkdir -p "$OUT_DIR"
RAW_OUT="$OUT_DIR/check_update_raw.txt"
PKGS_OUT="$OUT_DIR/pkgs.txt"
INST_OUT="$OUT_DIR/installed_before.txt"

# 1) check-update を実行し、生出力を保存 → 整形して標準出力＆ファイルへ
( yum check-update -q || true ) \
  | tee "$RAW_OUT" \
  | awk -v pkgfile="$PKGFILE" '
      BEGIN {
        if (pkgfile != "") {
          while ((getline l < pkgfile) > 0) {
            gsub(/[\r\n]+$/, "", l)
            gsub(/^\s+|\s+$/, "", l)
            if (l == "") continue
            allowFull[l] = 1
            base = l; sub(/\.[^.]*$/, "", base)
            allowBase[base] = 1
          }
          close(pkgfile)
        }
      }
      NF>=2 && $1 ~ /\.[^.]+$/ {
        na=$1; ver=$2; if (ver ~ /^@/) next
        arch=na; sub(/.*\./, "", arch)
        name=na; sub(/\.[^.]*$/, "", name)
        if (pkgfile != "" && !((na in allowFull) || (name in allowBase))) next
        printf "%s %s.%s\n", name, ver, arch
      }' \
  | sort -u \
  | tee "$PKGS_OUT"

# 2) 現在インストールされているバージョンの一覧を作成
NAMES_TMP=$(mktemp)
awk '{print $1}' "$PKGS_OUT" | sort -u > "$NAMES_TMP"
: > "$INST_OUT"
while IFS= read -r pname || [[ -n "$pname" ]]; do
  [[ -z "$pname" ]] && continue
  if rpm -q --qf '%{NAME} %{VERSION}-%{RELEASE}.%{ARCH}\n' "$pname" >/dev/null 2>&1; then
    rpm -q --qf '%{NAME} %{VERSION}-%{RELEASE}.%{ARCH}\n' "$pname" >> "$INST_OUT"
  else
    echo "$pname not-installed" >> "$INST_OUT"
  fi
done < "$NAMES_TMP"

echo "[gen-pkgs.sh] Saved: $RAW_OUT" >&2
echo "[gen-pkgs.sh] Saved: $PKGS_OUT" >&2
echo "[gen-pkgs.sh] Installed versions snapshot: $INST_OUT" >&2

