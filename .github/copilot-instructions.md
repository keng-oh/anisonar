# GitHub Copilot Instructions — アニソンDB

## プロジェクト概要

アニメ作品に紐づく楽曲（OP/ED/挿入歌/イメージソング）を管理・検索できるデータベースサービス。
Spotify等のストリーミングサービスとのプレイリスト連携も提供する。

詳細仕様: [docs/concept.md](../docs/concept.md)

## 技術スタック

| 領域           | 技術                               |
| -------------- | ---------------------------------- |
| Backend        | Ruby on Rails（通常モード）        |
| Database       | PostgreSQL                         |
| 非同期ジョブ   | Sidekiq                            |
| Frontend       | Hotwire（Turbo + Stimulus）        |
| CSS            | Tailwind CSS v4 + daisyUI v5       |
| コンポーネント | ViewComponent                      |
| 外部API        | Annict API（GraphQL）、Spotify API |

## MVPスコープ（現フェーズ）

**目標: 「アニメ→楽曲→Spotifyで聴く」最小限の体験**

含める:

- Annict APIからアニメ情報を取得・同期
- AIによる楽曲情報の収集・仮登録
- 管理者による手動承認
- アニメ検索・詳細画面
- 楽曲詳細画面（Spotifyリンク）
- 管理者向けレビューキュー

含めない（MVP後）:

- ユーザー登録 / コミュニティレビュー
- 自動承認ロジック
- プレイリスト作成機能
- Amazon Music / Apple Music連携
- アーティスト詳細ページ
- API公開

詳細は [docs/concept.md](../docs/concept.md) のセクション4参照。

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
  concept.md      # サービス仕様書
```

## よく使うコマンド

```bash
# .env 生成（初回・Doppler 側で値を変更したとき）
doppler secrets download --no-file --format env > .env

# サーバー起動
docker compose up

# テスト実行
bundle exec rspec

# Linter
bundle exec rubocop

# DBリセット
bin/rails db:reset

# Sidekiq
bundle exec sidekiq

# Annictデータ同期（実装後）
bin/rails annict:sync
```
