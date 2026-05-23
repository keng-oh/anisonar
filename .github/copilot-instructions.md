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
| JS             | Alpine.js                          |
| CSS            | Tailwind CSS + daisyUI             |
| コンポーネント | ViewComponent                      |
| 外部API        | Annict API（GraphQL）、Spotify API |

## 開発方針

- 仕事と並行（週10〜15時間）のため、**完成より早期リリースを優先**
- 3ヶ月以内の一般公開を目標
- MVPスコープを厳守し、後回しにできるものは後回しにする
- 受託なし、プロダクト単体での収益化を目指す

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

## DBスキーマ（概要）

```
anime_series → animes → anime_songs → songs
                                         ↓
                                   platform_links (Spotify等)

artists (person/unit/character)
  └ artist_relations (voice_of / member_of)

songs → reviews → (自動承認ロジック)
```

### モデルのアソシエーション

```ruby
Anime belongs_to :anime_series, optional: true
Anime has_many :songs, through: :anime_songs

Song belongs_to :artist
Song has_many :animes, through: :anime_songs
Song has_many :platform_links
Song has_many :reviews

Artist has_many :songs
# artist_type: person / unit / character
```

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
