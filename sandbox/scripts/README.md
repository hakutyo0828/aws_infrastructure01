# Scripts Usage (Amazon Linux 2 / yum)

このディレクトリのスクリプトで、更新候補の取得と指定版への適用を再現性高く実行できます。

- 生成: `gen-pkgs.sh` — 更新候補を `pkgs.txt` 形式で出力
- 適用: `yum-upgrade.sh` — `pkgs.txt` の版に合わせてインストール/ダウングレード（任意で固定）

## 前提
- 対象OS: Amazon Linux 2（yum）。sudo 権限があること。
- ネットワーク: インターネット到達（または VPC エンドポイントで閉域運用）。
- 置き場所の例: `/opt/scripts`（`chmod +x /opt/scripts/*.sh` を付与）

## pkgs.txt の作り方（gen-pkgs.sh）
- yum check-update を解析（既定）
  - `bash gen-pkgs.sh -o /tmp/pkgs.txt`
- repoquery で正確な更新候補
  - 全更新: `bash gen-pkgs.sh --repo -o /tmp/pkgs.txt`
  - セキュリティのみ: `bash gen-pkgs.sh --repo --security -o /tmp/pkgs.txt`
- 既存の check-update 出力から
  - `yum check-update > /tmp/cu.txt || true`
  - `bash gen-pkgs.sh -i /tmp/cu.txt -o /tmp/pkgs.txt`

出力形式: 1 行に 1 パッケージ `name version-release.arch`
- 例: `curl 7.55.1-8.amzn2.0.1.x86_64`
- サンプル: `pkgs.example.txt`

## 生成直後にそのまま適用（ワンコマンド）
- 依存置換許可＋固定（versionlock）
  - `bash gen-pkgs.sh -o /tmp/pkgs.txt --pin --allow-erasing -l`

## 適用（yum-upgrade.sh）
- ドライラン（変更なし）
  - `bash yum-upgrade.sh -f /tmp/pkgs.txt --dry-run`
- 実適用
  - `sudo bash yum-upgrade.sh -f /tmp/pkgs.txt`
  - 依存置換が必要な場合: `--allow-erasing`
  - 適用後に固定する場合: `-l`（yum-plugin-versionlock を利用）
- 固定解除
  - `sudo yum versionlock list`
  - `sudo yum versionlock delete <pkg>*`

## SSM で横展開（例）
- Document: AWS-RunShellScript
- Commands 例（`/opt/scripts` に配置済みを想定）
```
["bash /opt/scripts/gen-pkgs.sh -o /tmp/pkgs.txt",
 "sudo bash /opt/scripts/yum-upgrade.sh -f /tmp/pkgs.txt --allow-erasing -l"]
```
- ターゲットは InstanceIds でもタグ（例: `PatchGroup=linux-common`）でも可。

## トラブルシュート
- 該当版が見つからない
  - `sudo yum clean all && sudo yum makecache`
  - `sudo yum --showduplicates list <pkg>` で候補確認
  - リポが無効なら `sudo yum -y install yum-utils && sudo yum-config-manager --enable amzn2-core`
- 依存衝突
  - `--allow-erasing` を付与
  - 依存パッケージも同じ版で `pkgs.txt` に含める（例: curl と libcurl）
- NAT なし・完全プライベート
  - SSM: Interface エンドポイント（`ssm`, `ssmmessages`, `ec2messages`）
  - yum: S3 Gateway エンドポイント（`com.amazonaws.<region>.s3`）またはローカルリポ構築

## ヒント
- 前後差分: `rpm -qa --qf "%{NAME}-%{VERSION}-%{RELEASE}.%{ARCH}\n" | sort > before.txt`（適用後は after.txt）
- クリティカルなパッケージ（kernel/glibc/openssl）は事前に AMI 作成を推奨
- マルチアカウント（dev/stg/prod）は同じ `pkgs.txt` を使い、SSMタグ指定で同一実行

