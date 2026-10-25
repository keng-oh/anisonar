---
paths:
  - "app/**/*.rb"
  - "lib/**/*.rb"
  - "config/**/*.rb"
---

# Rails コーディング規約

## 配置と命名（既存コードに合わせる）

- 業務ロジック・外部連携は `app/services/<domain>/` に置き、ドメインの module で名前空間を切る
  - 例: `Songs::ArtistResolver`, `Deduplication::SongMerger`, `Annict::SyncAnimesService`, `Spotify::Client`
  - クラス名は役割を表す名詞（`Resolver`, `Merger`, `Client` など）。`XxxService` も既存にあるが必須ではない
- サービスの呼び出し形はクラスメソッド `call` に揃える:

  ```ruby
  def self.call(...) = new(...).call
  ```

- 外部クライアントや依存は `initialize` のキーワード引数で受け取り、デフォルトで実体を入れる
  （テストで差し替えるため）: `def initialize(items:, spotify_client: Spotify::Client.new)`
- 外部 API クライアントは `class Error < StandardError; end` を持ち、呼び出し側はそれを rescue する
- 状態を持たない変換・正規化は `app/lib/`（例: `NameNormalizer`, `UrlDeduplicator`）
- Sidekiq ジョブは `app/jobs/`、命名は `XxxJob`。重い処理はジョブに逃がし、ジョブからサービスを呼ぶ
- コントローラーは薄く（RESTful の 7 アクション）。管理画面は `Admin::`、API は `Api::Admin::` / `Api::N8n::`
- ファットモデル禁止。モデルはアソシエーション・バリデーション・enum・スコープまで

## enum の衝突回避（必須）

`insert` / `reject` などは ActiveRecord のメソッドと衝突するため prefix を付ける
（`AnimeSong` / `SeriesSong` / `Review` が実例）:

```ruby
enum :song_type, { op: 0, ed: 1, insert: 2, image: 3, soundtrack: 4, other: 5 }, prefix: :song
enum :action,    { approve: 0, reject: 1, flag: 2 }, prefix: :review
```

## その他

- N+1 は bullet で検出されたら即修正する
- マイグレーションを足したら、既存データへの影響を PR に書く
  （本番は web コンテナ起動時に `bin/docker-entrypoint` が `db:prepare` を流す）
- rake タスクを足したら、本番で流す必要があれば `.github/workflows/rake_task.yml` の選択肢にも追加する
- コメントは WHY が非自明なときだけ書く。外部 API の制約・仕様変更の注意点は必ずコメントに残す
