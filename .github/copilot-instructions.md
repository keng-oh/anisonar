# GitHub Copilot Instructions — アニソンDB

## プロジェクト概要

アニメ楽曲（OP/ED/挿入歌/イメージソング）を管理・検索できるデータベースサービス。
Ruby on Rails製。Annict API（GraphQL）でアニメ情報を取得し、AIで楽曲情報を収集する。

詳細仕様: `docs/concept.md`

## 技術スタック

- **Backend**: Ruby on Rails
- **Database**: PostgreSQL
- **非同期**: Sidekiq
- **Frontend**: Hotwire (Turbo + Stimulus) + Alpine.js
- **CSS**: Tailwind CSS + daisyUI
- **コンポーネント**: ViewComponent
- **外部API**: Annict (GraphQL), Spotify API

## コード生成の指針

### 基本方針
- MVPフェーズなので、過度な抽象化・汎用化はしない
- シンプルで読みやすいコードを優先する
- N+1クエリを避け、必要なアソシエーションは `includes` でプリロードする
- 外部APIの呼び出しはサービスオブジェクト (`app/services/`) にカプセル化する

### Rails規約
- ファットモデルを避け、ビジネスロジックはサービスオブジェクトに切り出す
- コントローラーは薄く保つ（7アクション原則）
- スコープはモデルに定義する
- ViewComponentでUIコンポーネントを管理する

### モデル設計

主要モデルと関係:
```ruby
# アニメ情報（Annictから同期）
Anime belongs_to :anime_series, optional: true
Anime has_many :anime_songs
Anime has_many :songs, through: :anime_songs

# 楽曲
Song belongs_to :artist
Song has_many :anime_songs
Song has_many :animes, through: :anime_songs
Song has_many :platform_links
Song has_many :reviews

# アーティスト（声優/ユニット/キャラクター）
Artist has_many :artist_relations
# artist_type: "person" / "unit" / "character"
```

### enumの使い方
```ruby
# Songのステータス
enum :status, { pending: 0, reviewing: 1, approved: 2, rejected: 3 }

# Songの種別
enum :song_type, { op: 0, ed: 1, insert: 2, image: 3 }

# Artistの種別
enum :artist_type, { person: 0, unit: 1, character: 2 }
```

### 外部API
- Annict: `app/services/annict/` 以下にGraphQLクエリを配置
- Spotify: `app/services/spotify/` 以下に配置
- AI収集: `app/services/ai/` 以下に配置
- 環境変数: `ANNICT_API_TOKEN`, `SPOTIFY_CLIENT_ID`, `SPOTIFY_CLIENT_SECRET`

### テスト
- RSpec + FactoryBot を使用
- 外部APIはVCRカセットでモック
- `spec/factories/` にファクトリを配置

### 命名規則
- サービスオブジェクト: `動詞 + 名詞` (例: `FetchAnimeJob`, `SyncAnimeService`)
- Sidekiqジョブ: `XxxJob` (`app/jobs/`)
- GraphQLクライアント: `app/services/annict/client.rb`

## コメントについて
- WHYが非自明な場合のみコメントを書く
- 外部APIの制約・仕様変更の注意点は必ずコメントに残す
- Spotifyは2026年2月にAPI仕様変更があったため、実装前に公式ドキュメントを確認すること
