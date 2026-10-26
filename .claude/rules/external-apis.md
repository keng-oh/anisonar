---
paths:
  - "app/services/annict/**/*.rb"
  - "app/services/anilist/**/*.rb"
  - "app/services/spotify/**/*.rb"
  - "app/services/ai/**/*.rb"
  - "app/services/notifications/**/*.rb"
  - "app/controllers/api/n8n/**/*.rb"
---

# 外部連携の規約

## 共通

- HTTP は Faraday。クライアントクラスに閉じ込め、サービスからはクライアント経由で呼ぶ
- 認証情報は `ENV` から `initialize` のデフォルト引数で受け取る（テストで差し替えられるように）
- 失敗は `<Client>::Error` に包んで投げる。呼び出し側は 1 件の失敗で全体を止めず、
  記録して次へ進む（部分失敗の扱いは `Songs::ArtistResolver` を参考に）
- 想定外の失敗は `Rails.error.report` で報告する。`Notifications::ErrorReporter` が購読していて
  ntfy / Discord に通知する（`config/initializers/error_reporting.rb`、未設定なら送らない）
- API の制約・レート制限・仕様変更の注意はコードにコメントで残す

## Annict（`app/services/annict/`）

- GraphQL: `https://api.annict.com/graphql`、`ANNICT_API_TOKEN`
- 取れるのはアニメ・シリーズ・エピソード。**楽曲情報は含まれない**（楽曲は AI 収集で集める）

## AniList（`app/services/anilist/`）

- カバー画像の解決に使う。認証不要

## AI 楽曲収集（`app/services/ai/`, `app/services/songs/ai_researcher.rb`）

- Claude: `Ai::ClaudeClient`（`ANTHROPIC_API_KEY`）
- Firecrawl（セルフホスト）: `Ai::FirecrawlClient`（`FIRECRAWL_URL`, `FIRECRAWL_API_KEY`）
- AI が作ったデータは AI ボット用ユーザー（`User::AI_USER_EMAIL`、role: ai）の作成として記録する
  （`created_by_user_id`）

## n8n 連携 API（`app/controllers/api/n8n/`）

- n8n からクロール対象（crawl_requests）を取得・更新する。`N8N_API_TOKEN` で認証
- レスポンスの形を変えると n8n 側のワークフローが壊れる。変えるときは PR に明記する
