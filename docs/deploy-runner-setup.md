# 自宅CTへのGitHub Actions self-hosted runnerセットアップ

ProxmoxのDocker用CT上で、GitHub Actionsのデプロイジョブをローカルでpullして起動できるようにするための手順。
対象ワークフロー: `.github/workflows/deploy.yml` の `deploy` ジョブ（ラベル: `self-hosted`, `anisonar`）。

## 前提

- CT上にDockerとDocker Composeが導入済み
- リポジトリ `keng-oh/anisonar` への Settings 権限がある

## 1. 必要パッケージのインストール

```sh
# Docker CLI（compose plugin含む）が無ければ
curl -fsSL https://get.docker.com | sh

# Doppler CLI
curl -Ls https://cli.doppler.com/install.sh | sh
```

## 2. runnerユーザーの作成（推奨: 専用ユーザーで実行）

```sh
useradd -m -s /bin/bash ghrunner
usermod -aG docker ghrunner
su - ghrunner
```

## 3. runnerのダウンロードと登録

1. GitHubで対象リポジトリを開く → Settings → Actions → Runners → "New self-hosted runner" を選択
2. 表示されるOS/archに応じたダウンロード〜登録コマンドをコピーして実行（トークンは画面に都度発行されるため、その場でコピーする）

```sh
mkdir actions-runner && cd actions-runner
curl -o actions-runner-linux-x64-<version>.tar.gz -L https://github.com/actions/runner/releases/download/v<version>/actions-runner-linux-x64-<version>.tar.gz
tar xzf actions-runner-linux-x64-<version>.tar.gz
./config.sh --url https://github.com/keng-oh/anisonar --token <GitHubが発行したトークン>
```

3. ラベル入力を求められたら `anisonar` を追加する（デフォルトの `self-hosted` は自動付与される）

## 4. サービス化（再起動後も自動起動）

```sh
sudo ./svc.sh install
sudo ./svc.sh start
```

## 5. リポジトリSecretsの登録

リポジトリの Settings → Secrets and variables → Actions に以下を登録:

- `DOPPLER_TOKEN`: Dopplerのproduction config用サービストークン（`doppler configs tokens create --project <project> --config <prd-config>` で発行）

`GITHUB_TOKEN` はGitHub Actionsが自動発行するため登録不要。

## 6. 動作確認

```sh
# runnerユーザーで
docker info        # Dockerにアクセスできるか
doppler --version  # Doppler CLIが入っているか
```

mainブランチにpushすると `deploy` ジョブがこのrunner上で実行され、`docker compose -f docker-compose.prod.yml up -d` がDopplerのシークレットを注入した状態で走る。

## メンテナンス

- runnerの更新: GitHub側で新バージョンが出たら `actions-runner` ディレクトリ内で `./config.sh remove` → 再ダウンロード → 再登録、または自動更新を有効化
- ログ確認: `journalctl -u actions.runner.* -f`
