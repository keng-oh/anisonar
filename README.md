# Anisonar

[![CI](https://github.com/keng-oh/anisonar/actions/workflows/ci.yml/badge.svg)](https://github.com/keng-oh/anisonar/actions/workflows/ci.yml)
[![Deploy](https://github.com/keng-oh/anisonar/actions/workflows/deploy.yml/badge.svg)](https://github.com/keng-oh/anisonar/actions/workflows/deploy.yml)
[![Release](https://img.shields.io/github/v/release/keng-oh/anisonar)](https://github.com/keng-oh/anisonar/releases)
![Ruby](https://img.shields.io/badge/Ruby-3.4.9-CC342D)
![Rails](https://img.shields.io/badge/Rails-8.1-CC0000)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-4169E1)

アニメ作品に紐づく楽曲（OP/ED/挿入歌/イメージソング）を網羅的に管理・検索できるデータベースサービス。
楽曲データを資産として、Spotifyなどのストリーミングサービスとのプレイリスト連携も提供する。

詳細仕様は [docs/concept.md](docs/concept.md) を参照。

## 技術スタック

| 領域           | 技術                               |
| -------------- | ---------------------------------- |
| Backend        | Ruby on Rails（通常モード）        |
| Database       | PostgreSQL                         |
| 非同期ジョブ   | Sidekiq                            |
| Frontend       | Hotwire（Turbo + Stimulus）        |
| JS             | Alpine.js                          |
| CSS            | Tailwind CSS v4 + daisyUI v5       |
| コンポーネント | ViewComponent                      |
| 外部API        | Annict API（GraphQL）、Spotify API |

## セットアップ

### 必要なもの

- Docker / Docker Compose
- [Doppler CLI](https://docs.doppler.com/docs/install-cli)（環境変数管理）

### 初回セットアップ

```bash
# Dopplerから環境変数を取得
doppler secrets download --no-file --format env > .env

# イメージビルド & 起動
docker compose up
```

`http://localhost:3000` で起動する。

### よく使うコマンド

```bash
# サーバー起動
docker compose up

# テスト実行（RAILS_ENV未指定だとdevelopmentで動いてしまうので明示する）
RAILS_ENV=test bundle exec rspec

# Linter
bundle exec rubocop

# DBリセット
bin/rails db:reset

# Annictデータ同期
bin/rails annict:sync

# 本番の定時ダンプをローカルDBへ反映（usersは除外されプレースホルダーに置換）
export ANISONAR_PROD_HOST=root@<本番ホスト>
export ANISONAR_PROD_SSH_KEY=~/.ssh/anisonar.pub  # ssh agentの鍵が多くて認証に失敗する場合
bin/db-pull
```

## ディレクトリ構成

```
app/
  components/     # ViewComponent
  jobs/           # Sidekiqジョブ
  services/       # サービスオブジェクト
    annict/       # Annict API連携
    spotify/      # Spotify API連携
    ai/           # AI楽曲収集
  models/
  controllers/
  views/
docs/
  concept.md                 # サービス仕様書
  deploy-runner-setup.md     # self-hosted runnerセットアップ手順
```
