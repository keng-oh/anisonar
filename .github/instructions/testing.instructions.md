---
applyTo: "spec/**/*.rb"
---

# テスト規約

- RSpec を使用する
- FactoryBot でテストデータを生成する
- モデルのバリデーション・スコープは必ずテストする
- 外部 API（Annict, Spotify）は VCR カセットでモックする
