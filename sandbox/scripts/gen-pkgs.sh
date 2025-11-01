#!/usr/bin/env bash
# gen-pkgs.sh : yum check-update を実行し、"name version-release.arch" を出力します

set -euo pipefail

( yum check-update -q || true ) \
  | awk 'NF>=2 && $1 ~ /\.[^.]+$/ { \
        na=$1; ver=$2; if (ver ~ /^@/) next; \
        arch=na; sub(/.*\./, "", arch); name=na; sub(/\.[^.]*$/, "", name); \
        printf "%s %s.%s\n", name, ver, arch \
      }' \
  | sort -u
