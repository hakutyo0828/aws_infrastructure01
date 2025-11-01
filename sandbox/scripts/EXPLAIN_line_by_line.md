# Line-by-Line Explanations (scripts)

このドキュメントはスクリプトを行単位で説明します。

---

## gen-pkgs.sh (gen-pkgs.sh > package.txt)
- 目的: yum の更新候補を name version-release.arch 形式で出力し、後段に渡す。
- 1: #!/usr/bin/env bash — bash で実行。
- 2: コメント — スクリプト概要。
- 3: set -euo pipefail — 厳格モード（errexit, nounset, pipefail）。
- 4: ( yum check-update -q || true ) — 更新候補を取得。終了コード100を無視して出力だけ使う。
- 5: | awk '…' — name.arch version-release repo の行だけを拾い、name と arch を分離し name version-release.arch に整形。
- 6: | sort -u — 重複除去。

## yum-upgrade.sh (yum-upgrade.sh -f package.txt)
- 目的: pkgs.txt の内容（NEVRA相当）だけを upgrade で適用。
- 1: #!/usr/bin/env bash — bash で実行。
- 2: set -euo pipefail — 厳格モード。
- 3: usage() — 使い方表示関数。
- 4: 引数パース（-f/--file のみ必須、-h/--help は表示）。
- 5: 入力ファイル存在チェック（未指定/不存在なら終了）。
- 6: YUM=${YUM:-yum} — 実行コマンドを環境変数で上書き可能に。
- 7: NEVRAS=() — 適用対象の配列。
- 8: while ループ — pkgs.txt を1行ずつ処理。#以降をコメント扱い、空行スキップ、1列目name・2列目version-release.arch を取得して name-version-release.arch を配列に格納。
- 9: echo/printf — 適用対象を表示。
- 10: set -x; yum -y upgrade …; set +x — アップグレードのみ実行（未インストールは対象外）。
- 11: Done. — 終了メッセージ。

---

補足
- pkgs.txt の行書式: name version-release.arch（例: curl 8.3.0-1.amzn2.0.9.x86_64）。
- アップグレードのみのため、指定版が現行より古い場合は適用されません（ダウングレードは別途）。
- 依存関係により最小限の同伴更新が発生することがあります。
