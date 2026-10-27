# CLAUDE.md — Anisonar

アニメ作品に紐づく楽曲（OP/ED/挿入歌/イメージソング）を管理・検索するデータベースサービス。
MVP の目的は「アニメから関連楽曲を調べて Spotify で聴ける」体験。

## ドメイン

- アニメ（`animes`）とシリーズ（`anime_series`）は Annict から同期する
- 楽曲（`songs`）はアニメ（`anime_songs`）またはシリーズ（`series_songs`）に、種別（OP / ED / 挿入歌 ...）付きで紐づく
- アーティスト（`artists`）は person / unit / character の 3 種。`artist_relations` で
  「声優 → キャラクター（voice_of）」「声優 → ユニット（member_of）」を表す
- 楽曲は n8n のワークフローが収集し（Wikipedia を前処理して LLM で抽出）、クロールキュー（`crawl_requests`）経由で取り込む。
  AI が作ったデータは AI ボット用ユーザーの作成として記録する
- 配信サービスへのリンクは `platform_links`、アルバムは `albums`（Spotify）

**最新のデータ構造は `db/schema.rb` が正。** サービスの構想・ロードマップは GitHub Wiki にある
（`git clone https://github.com/keng-oh/anisonar.wiki.git`、Concept / Roadmap ページ）。
構想は実装と異なる部分があるので、食い違ったらコードと schema を優先する。
個別の作業の仕様は GitHub Issue の本文に書く。

## 技術スタック

- Ruby 3.4.9 / Rails 8.1（通常モード）/ PostgreSQL 16 / Sidekiq 8 + Redis
- Hotwire（Turbo + Stimulus）、Tailwind CSS v4 + daisyUI v5、esbuild
- 認証は Devise。ViewComponent の gem は入っているが `app/components/` はまだ無い
- テスト: RSpec / FactoryBot / shoulda-matchers / WebMock（VCR の gem もある）
- 品質: rubocop-rails-omakase / brakeman / bundler-audit

## 構成

```text
app/
  services/<domain>/   # 外部連携・業務ロジック（Annict, AniList, Spotify, Songs, Artists, Deduplication, Notifications ...）
  lib/                 # 状態を持たないユーティリティ（NameNormalizer, UrlDeduplicator ...）
  jobs/                # Sidekiq ジョブ（XxxJob）
  controllers/admin/   # 管理画面
  controllers/api/     # admin 用 API と n8n 連携 API（api/n8n）
lib/tasks/             # rake タスク（annict:sync, deduplication:*, cover_images:* ...）
```

ファイル種別ごとの規約は `.claude/rules/` にあり、該当ファイルを触るときに読み込まれる。

## 開発環境

**開発は Docker（`docker-compose.yml` / `Dockerfile.dev`）で行う。** ホストに Ruby 3.4.9 は無い前提で、
Ruby / Rails のコマンドはすべてコンテナ内で実行する。

```bash
docker compose up -d web            # web + db + redis（js / css / worker は必要なときだけ）
docker compose run --rm web <cmd>   # 例: docker compose run --rm web bin/rails c
```

- `.env` が必要（compose の `env_file`）。通常は Doppler から生成する:
  `doppler secrets download --no-file --format env > .env`
  Doppler が無い環境（開発 VM など）では `cp .env.example .env` で起動とテストはできる
- `.env` は秘密情報を含みうるので、読んだり内容を出力したりしない
- `bin/db-pull`（本番ダンプの取り込み）は本番に接続するので実行しない

## 完了の判定（push 前に必ず通す）

CI（`.github/workflows/ci.yml`）と同じ 4 つ。全部通ってから push する。

```bash
docker compose up -d db redis
docker compose run --rm -e RAILS_ENV=test web bin/rails db:test:prepare
docker compose run --rm -e RAILS_ENV=test web bundle exec rspec
docker compose run --rm --no-deps web bundle exec rubocop
docker compose run --rm --no-deps web bin/brakeman --no-pager
docker compose run --rm --no-deps web bin/bundler-audit
```

- テストは必ず `RAILS_ENV=test`。未指定だと development DB で動く
- テスト DB は `db:test:prepare` で作る。`db:prepare` / `db:setup` は seed やデータ移行まで流れ、
  テストが「メールアドレスはすでに存在します」等で落ちる
- `bin/brakeman` は `--ensure-latest` 付き。brakeman が最新版でないだけで失敗するので、
  そのときは `bundle update --conservative brakeman`
- Gemfile / Gemfile.lock を変えたら `docker compose build web` でイメージを作り直す

## Git・デプロイ

- 作業は main から切った feature ブランチ（`feat/...`, `fix/...`, `chore/...`）で行い、push まで
- **Issue・PR の作成や更新（本文の編集・コメント・クローズを含む）は、先に文面を見せてユーザーの承認を得てから**
  `gh` で書き込む。承認なしに GitHub へ書き込まない
- main は ruleset で保護されている（PR 必須、CI: test / lint / scan_ruby 必須）
- **本番デプロイは `v*.*.*` タグの push で走る**（`.github/workflows/deploy.yml`、self-hosted runner）。
  main への merge では本番は変わらない。**タグを作成・push しない**
- 本番の環境変数は Doppler で管理し、デプロイ時に `doppler run` で注入される
- 本番で rake タスクを流すのは `.github/workflows/rake_task.yml`（手動実行）。直接本番に入らない
- コミットメッセージは Conventional Commits 風（`feat:` / `fix:` / `build(deps):` ...）、本文は日本語でよい
- PR 本文は `.github/pull_request_template.md` の形式、Issue は `.github/ISSUE_TEMPLATE/` の形式

## 外部連携

| 連携 | 場所 | 環境変数 |
| --- | --- | --- |
| Annict（GraphQL） | `app/services/annict/` | `ANNICT_API_TOKEN` |
| AniList（カバー画像） | `app/services/anilist/` | なし |
| Spotify | `app/services/spotify/` | `SPOTIFY_CLIENT_ID`, `SPOTIFY_CLIENT_SECRET` |
| n8n（クロールキュー） | `app/controllers/api/n8n/` | `N8N_API_TOKEN` |
| 通知（ntfy / Discord） | `app/services/notifications/` | `NTFY_URL`, `DISCORD_WEBHOOK_URL` 等 |
| メール（Resend） | `config/initializers/resend.rb`（本番の delivery_method） | `RESEND_API_KEY` |

変数の一覧は `.env.example`。新しい変数を足したら `.env.example` と `docker-compose.prod.yml` も更新し、
PR の「本番反映時に必要な作業」に Doppler への追加を書く。
