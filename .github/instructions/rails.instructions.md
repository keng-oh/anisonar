---
applyTo: '**/*.rb'
---

# Rails コーディング規約

## 構成ルール

- Rubocop に従う（設定は `.rubocop.yml` 参照）
- サービスオブジェクトは `app/services/` に配置、命名は `動詞 + Service`（例: `SyncAnimeService`）
- Sidekiq ジョブは `app/jobs/` に配置、命名は `XxxJob`
- ViewComponent は `app/components/` に配置
- N+1 クエリは bullet gem で検出・即修正
- ビジネスロジックはサービスオブジェクトに切り出す（ファットモデル禁止）
- コントローラーは薄く保つ（7アクション原則）

## 命名規則

| 種別                 | 規則                   | 例                           |
| -------------------- | ---------------------- | ---------------------------- |
| モデル               | 単数形・英語           | `Anime`, `Song`, `Artist`    |
| テーブル             | 複数形・スネークケース | `animes`, `songs`, `artists` |
| サービスオブジェクト | 動詞 + Service         | `SyncAnimeService`           |
| Sidekiq ジョブ       | XxxJob                 | `SyncAnimeJob`               |
| ルーティング         | RESTful 原則           |                              |

## enum の衝突回避（必須）

`insert` / `reject` は ActiveRecord のメソッドと衝突するため prefix が必要:

```ruby
enum :song_type, { op: 0, ed: 1, insert: 2, image: 3, soundtrack: 4, other: 5 }, prefix: :song
enum :action,    { approve: 0, reject: 1, flag: 2 },     prefix: :review
```

## コメント規約

- WHY が非自明な場合のみ書く
- 外部 API の制約・仕様変更の注意点は必ずコメントに残す
