---
applyTo: "app/services/{annict,spotify,ai}/**/*.rb"
---

# 外部 API 規約

## Annict API

- GraphQL endpoint: `https://api.annict.com/graphql`
- 環境変数: `ANNICT_API_TOKEN`
- 取得対象: アニメ・シリーズ・エピソード情報（楽曲情報は含まれない）
- 配置先: `app/services/annict/`

## Spotify API

- 環境変数: `SPOTIFY_CLIENT_ID`, `SPOTIFY_CLIENT_SECRET`
- **2026年2月の API 変更で仕様変更あり。実装前に必ず公式ドキュメントを確認すること**
- 配置先: `app/services/spotify/`

## AI 楽曲収集

- 配置先: `app/services/ai/`
