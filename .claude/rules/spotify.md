---
paths:
  - "app/services/spotify/**/*.rb"
---

# Spotify Web API

- エンドポイント・パラメータ・レスポンスは推測せず、OpenAPI スキーマで確認する:
  https://developer.spotify.com/reference/web-api/open-api-schema.yaml
  （2026 年 2 月に API 仕様の変更がある。実装前に公式ドキュメントを確認する）
- 認可フロー: 公開データだけなら Client Credentials（現状の `Spotify::Client`）。
  ユーザーのデータを扱うなら Authorization Code（バックエンドあり）か PKCE。Implicit Grant は使わない
- リダイレクト URI は HTTPS（ローカル開発のみ `http://127.0.0.1` 可、`localhost` やワイルドカードは不可）
- スコープは必要最小限。先回りして広く取らない
- Client Secret をクライアント側に出さない。トークンは更新処理を実装し、期限切れなら再認可させる
- 429 は `Retry-After` を守って指数バックオフ。即時リトライやループで叩かない
- 非推奨エンドポイントを使わない（`/playlists/{id}/tracks` ではなく `/playlists/{id}/items`、
  種別ごとのライブラリ API ではなく `/me/library`）
- エラーは OpenAPI に定義されたコードを扱い、返ってきたメッセージを利用者向けの表示に使う
- 利用規約（https://developer.spotify.com/terms）を守る: 必要以上にコンテンツをキャッシュしない、
  Spotify のコンテンツであることを表示する、Spotify のデータで機械学習モデルを学習しない
