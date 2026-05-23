# 開発進捗ログ

- concept.md の推奨スケジュール（1ヶ月目：DBスキーマ・Annict同期・管理画面）に沿って進めている

## 完了済み

- 2026-05-22 — 環境構築・DBスキーマ・モデル
  - gem 整備
    - Sidekiq + Redis を追加（solid_queue を削除）
    - RSpec + FactoryBot + shoulda-matchers + VCR/WebMock を追加
    - ViewComponent、Pagy、Faraday、Devise、Bullet、annotaterb を追加
    - `config/initializers/sidekiq.rb`、`config/sidekiq.yml` を作成
    - `Procfile.dev` に `worker:` プロセスを追加
    - `config/database.yml` を DATABASE_URL から自動接続設定するよう変更
  - DB マイグレーション（全テーブル作成済み）
    - `anime_series` — annict_series_id にユニークインデックス
    - `animes` — annict_id にユニークインデックス、media_type / status は enum
    - `artists` — artist_type は enum、character 時は anime_id 必須
    - `artist_relations` — (from_artist_id, to_artist_id, relation_type) にユニーク複合インデックス
    - `songs` — song_type / status は enum、approve / reject カウントはデフォルト 0
    - `anime_songs` — (anime_id, song_id) にユニーク複合インデックス
    - `platform_links` — (song_id, platform) にユニーク複合インデックス
    - `users` — Devise、role と trusted_count を create_table に統合
    - `reviews` — (song_id, user_id) にユニーク複合インデックス
  - モデル（アソシエーション・バリデーション・enum）
    - `AnimeSeries` — has_many :animes
    - `Anime` — belongs_to :anime_series (optional)、enum media_type / status
    - `Artist` — enum artist_type、character 時のバリデーション
    - `ArtistRelation` — from_artist / to_artist の自己参照、enum relation_type
    - `Song` — enum song_type (prefix: :song)、enum status、`#spotify_link` ヘルパー
    - `AnimeSong` — 中間テーブル
    - `PlatformLink` — enum platform
    - `User` — Devise、enum role、`#review_weight` メソッド（1/2/3票）
    - `Review` — enum action (prefix: :review)
  - テスト基盤
    - RSpec 初期化済み（`spec/rails_helper.rb`）
    - `spec/support/shoulda_matchers.rb`、`spec/support/factory_bot.rb` 設定
    - `spec/factories/users.rb` — general / reviewer / admin / trusted トレイト付き
    - `spec/models/user_spec.rb` — 7 examples、全パス

- 2026-05-23 — ユーザーフロント・管理画面フロント
  - daisyUI v5 インストール・Tailwind v4 と連携設定
  - ルーティング設定（root, animes, songs, admin namespace）
  - Pagy を ApplicationController / ApplicationHelper に組み込み
  - `Song#approve!` / `Song#reject!` メソッド追加
  - `Anime.search` スコープ追加（ILIKE 全文検索）
  - ユーザー向けコントローラー
    - `AnimesController` — index（タイトル/シーズン検索・Pagy ページネーション）・show
    - `SongsController` — show
  - 管理コントローラー
    - `Admin::BaseController` — admin ロールチェック・admin レイアウト適用
    - `Admin::AnimesController` — index（検索）・edit・update
    - `Admin::SongsController` — index（pending_review 一覧）・approve・reject
  - レイアウト
    - `application.html.erb` — ナビバー（管理画面リンク・ログイン/ログアウト）・flash メッセージ
    - `admin.html.erb` — 管理専用レイアウト（night テーマ・管理ナビ）
  - ユーザー向けビュー
    - `animes/index` — グリッドカード表示・タイトル/シーズン検索フォーム
    - `animes/show` — カバー画像・楽曲一覧・Spotify リンクボタン
    - `songs/show` — 楽曲詳細・使用アニメ一覧・Spotify リンク
  - 管理者向けビュー
    - `admin/animes/index` — テーブル一覧・検索
    - `admin/animes/edit` — タイトル・メディア種別・シーズン・ステータス編集フォーム
    - `admin/songs/index` — レビューキュー（承認/否認ボタン付き）

## 次にやること

- 優先度：高（1ヶ月目スコープ）
  - Annict データ同期（コンソール or Rake タスクで手動実行）
    - `app/jobs/annict_sync_job.rb` — Sidekiq ジョブ化（任意）
    - `lib/tasks/annict.rake` — `bin/rails annict:sync` コマンド
  - Spotify API 連携
    - `app/services/spotify/client.rb` — Client Credentials フロー
    - `app/services/spotify/search_track_service.rb` — 曲名＋アーティスト名で検索
    - `PlatformLink` への保存
- 優先度：中（2ヶ月目スコープ）
  - AI 楽曲収集パイプライン（Wikipedia 等をウェブ検索）
  - 自動承認ロジック（閾値は定数 or 管理画面付き DB レコードで実装時に判断）
  - Tailwind CSS + daisyUI でのスタイリング
  - ViewComponent 導入（楽曲カード、レビューフォーム等）
- 優先度：低（MVP 後）
  - ユーザー登録 / コミュニティレビュー
  - プレイリスト作成機能
  - Amazon Music / Apple Music 連携
  - API 公開
