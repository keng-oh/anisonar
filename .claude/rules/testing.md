---
paths:
  - "spec/**/*.rb"
---

# テスト規約

- RSpec + FactoryBot。ファクトリは `spec/factories/`、共通設定は `spec/support/`
- 実行は CLAUDE.md の「完了の判定」の手順で（Docker 内、`RAILS_ENV=test`、テスト DB は `db:test:prepare`）
- モデルのバリデーション・スコープ・enum は必ずテストする（shoulda-matchers を使ってよい）
- サービスは公開インターフェース（`.call`）の入出力と副作用（作成されるレコード等）をテストする
- **外部 API は叩かない。** サービスが `initialize` で受け取るクライアントを `instance_double` で差し替える:

  ```ruby
  # Spotify matching is not this service's concern; inject a client that never matches
  let(:spotify_client) { instance_double(Spotify::Client, search_artist: []) }
  ```

  クライアント自体（`Spotify::Client` など）をテストするときは WebMock の `stub_request` で HTTP を止める
- 失敗系（クライアントの `Error`、部分的な失敗で処理が続くこと）もテストする
- AI ボット用ユーザーなど固定のメールアドレスを持つレコードは、テスト内で作る。
  seed のデータに依存しない（テスト DB は `db:test:prepare` で空の状態から作る）
- テストの説明文は日本語でよい（既存に合わせる）
