# Scripts Usage (Amazon Linux 2 / yum)

このディレクトリのスクリプトで、更新候補の取得と指定版への適用を再現性高く実行できます。

- 生成: `gen-pkgs.sh` — yum の出力を `pkgs.txt` 形式に整形
- 適用: `yum-upgrade.sh` — `pkgs.txt` の版へインストール/ダウングレード（任意で固定）

## 前提
- 対象OS: Amazon Linux 2（yum）。sudo 権限があること。
- ネットワーク: インターネット到達（または VPC エンドポイントで閉域運用）。
- 配置例: `/opt/scripts`（`chmod +x /opt/scripts/*.sh` を付与）

## pkgs.txt の作り方（最小）
- yum check-update を解析（既定）
  - `bash gen-pkgs.sh -o /tmp/pkgs.txt`
- 既存の出力ファイルから（check-update や update の結果を保存したもの）
  - `yum check-update > /tmp/cu.txt || true`
  - `bash gen-pkgs.sh -i /tmp/cu.txt -o /tmp/pkgs.txt`

出力形式: 1 行に 1 パッケージ `name version-release.arch`
- 例: `curl 8.3.0-1.amzn2.0.9.x86_64`
- サンプル: `pkgs.example.txt`

## 適用（yum-upgrade.sh）
- ドライラン（変更なし）
  - `bash yum-upgrade.sh -f /tmp/pkgs.txt --dry-run`
- 実適用
  - `sudo bash yum-upgrade.sh -f /tmp/pkgs.txt`
  - 依存置換が必要な場合: `--allow-erasing`
  - 適用後に固定する場合: `-l`（yum-plugin-versionlock を使用）
- 固定解除
  - `sudo yum versionlock list`
  - `sudo yum versionlock delete <pkg>*`

## SSM で横展開（例）
- Document: AWS-RunShellScript
- Commands（`/opt/scripts` に配置済み想定）
```
["bash /opt/scripts/gen-pkgs.sh -o /tmp/pkgs.txt",
 "sudo bash /opt/scripts/yum-upgrade.sh -f /tmp/pkgs.txt --allow-erasing -l"]
```

## トラブルシュート
- pkgs.txt が空になる
  - `yum check-update -q > /tmp/cu.txt || true` の内容を確認
  - `bash gen-pkgs.sh -i /tmp/cu.txt -o /tmp/pkgs.txt` を再実行
  - 改行正規化: `sed -i 's/\r$//' /tmp/cu.txt`
- 依存衝突
  - `--allow-erasing` を付与
  - 依存パッケージも同じ版で `pkgs.txt` に含める（例: curl と libcurl）

## ヒント
- 前後差分: `rpm -qa --qf "%{NAME}-%{VERSION}-%{RELEASE}.%{ARCH}\n" | sort > before.txt`（適用後は after.txt）
- 重要パッケージ（kernel/glibc/openssl）は適用前に AMI 取得を推奨

