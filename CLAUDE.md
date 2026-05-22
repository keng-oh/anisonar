# CLAUDE.md — アニソンDB

## プロジェクト概要

アニメ作品に紐づく楽曲（OP/ED/挿入歌/イメージソング）を管理・検索できるデータベースサービス。
Spotify等のストリーミングサービスとのプレイリスト連携も提供する。

詳細仕様: [docs/concept.md](docs/concept.md)

## 技術スタック

| 領域 | 技術 |
|------|------|
| Backend | Ruby on Rails（通常モード） |
| Database | PostgreSQL |
| 非同期ジョブ | Sidekiq |
| Frontend | Hotwire（Turbo + Stimulus） |
| JS | Alpine.js |
| CSS | Tailwind CSS + daisyUI |
| コンポーネント | ViewComponent |
| 外部API | Annict API（GraphQL）、Spotify API |

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

含めない（MVP後):
- ユーザー登録 / コミュニティレビュー
- 自動承認ロジック
- プレイリスト作成機能
- Amazon Music / Apple Music連携
- アーティスト詳細ページ
- API公開

## コーディング規約

### Rails
- Rubocopに従う（設定は`.rubocop.yml`参照）
- サービスオブジェクトは `app/services/` に配置
- Sidekiqジョブは `app/jobs/` に配置
- ViewComponentは `app/components/` に配置
- N+1クエリは `bullet` gem で検出・即修正

### 命名規則
- モデル: 単数形・英語（`Anime`, `Song`, `Artist`）
- テーブル: 複数形・スネークケース（`animes`, `songs`, `artists`）
- ルーティング: RESTful原則に従う

### テスト
- RSpec使用
- FactoryBot でテストデータ生成
- モデルのバリデーション・スコープは必ずテスト
- 外部API（Annict, Spotify）はVCRカセットでモック

## DBスキーマ（概要）

```
anime_series → animes → anime_songs → songs
                                         ↓
                                   platform_links (Spotify等)

artists (person/unit/character)
  └ artist_relations (voice_of / member_of)

songs → reviews → (自動承認ロジック)
```

詳細は [docs/concept.md](docs/concept.md) のセクション4参照。

## 外部API

### Annict API
- GraphQL endpoint: `https://api.annict.com/graphql`
- 環境変数: `ANNICT_API_TOKEN`
- 取得対象: アニメ・シリーズ・エピソード情報（楽曲情報なし）

### Spotify API
- 環境変数: `SPOTIFY_CLIENT_ID`, `SPOTIFY_CLIENT_SECRET`
- 2026年2月のAPI変更で仕様変更あり。実装前に公式ドキュメントを必ず確認すること

## よく使うコマンド

```bash
# サーバー起動
bin/dev

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

## ディレクトリ構成（予定）

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
