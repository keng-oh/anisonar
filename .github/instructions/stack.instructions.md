---
applyTo: '**/*'
---

# 技術スタック

## Backend

| Gem                         | 用途                                                         |
| --------------------------- | ------------------------------------------------------------ |
| `rails ~> 8.1.3`            | Webフレームワーク（通常モード）                              |
| `pg ~> 1.1`                 | PostgreSQL アダプター                                        |
| `puma >= 5.0`               | アプリケーションサーバー                                     |
| `propshaft`                 | アセットパイプライン                                         |
| `jbuilder`                  | JSON レスポンス生成                                          |
| `devise`                    | 認証（ユーザーログイン）                                     |
| `faraday` + `faraday-retry` | HTTP クライアント（Annict GraphQL・Spotify API）             |
| `view_component`            | UIコンポーネント（`app/components/` 配下）                   |
| `sidekiq ~> 7.0`            | バックグラウンドジョブ（`app/jobs/` 配下）                   |
| `redis ~> 5.0`              | Sidekiq のキューバックエンド                                 |
| `solid_cache`               | DB バックドキャッシュ（Rails 8 標準）                        |
| `solid_cable`               | DB バックド ActionCable（Rails 8 標準）                      |
| `bullet`                    | N+1 クエリ検出（development のみ）                           |
| `annotaterb`                | モデル・スキーマのアノテーション自動生成（development のみ） |
| `thruster`                  | HTTP キャッシュ・圧縮プロキシ                                |

## Frontend

| ライブラリ                       | 用途                                      |
| -------------------------------- | ----------------------------------------- |
| Turbo（`@hotwired/turbo-rails`） | ページ遷移・フォームの SPA ライク動作     |
| Stimulus（`@hotwired/stimulus`） | 軽量 JS コントローラー                    |
| Tailwind CSS v4                  | ユーティリティファーストCSS               |
| daisyUI v5                       | Tailwind ベースのコンポーネントライブラリ |
| esbuild                          | JS バンドラー                             |

- CSS ビルド: `npx @tailwindcss/cli`
- JS ビルド: `esbuild app/javascript/*.*`

## テスト

| Gem                 | 用途                                                     |
| ------------------- | -------------------------------------------------------- |
| `rspec-rails`       | テストフレームワーク                                     |
| `factory_bot_rails` | テストデータ生成                                         |
| `vcr` + `webmock`   | 外部 API のカセット記録・再生                            |
| `shoulda-matchers`  | モデルバリデーション・アソシエーションの簡潔なマッチャー |

## 環境変数管理

- **Doppler** を使用して環境変数を管理する
- `.env` は Doppler から生成する（直接編集しない・コミットしない）

```bash
# .env を生成（初回・Doppler 側で値を変更したとき）
doppler secrets download --no-file --format env > .env

# 以降は通常通り起動
docker compose up
```

管理する環境変数は `.env.example` 参照:

| 変数名                  | 用途                                 |
| ----------------------- | ------------------------------------ |
| `RAILS_MASTER_KEY`      | Rails 暗号化キー                     |
| `DATABASE_URL`          | PostgreSQL 接続先                    |
| `REDIS_URL`             | Redis 接続先（Sidekiq）              |
| `ANNICT_API_TOKEN`      | Annict API 認証トークン              |
| `SPOTIFY_CLIENT_ID`     | Spotify API クライアントID           |
| `SPOTIFY_CLIENT_SECRET` | Spotify API クライアントシークレット |

## コード品質

| Gem                     | 用途                            |
| ----------------------- | ------------------------------- |
| `rubocop-rails-omakase` | Linter（Railsチームの標準設定） |
| `brakeman`              | セキュリティ静的解析            |
| `bundler-audit`         | Gem の既知脆弱性チェック        |
