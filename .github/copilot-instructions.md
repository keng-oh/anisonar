# GitHub Copilot Instructions — アニソンDB

プロジェクトの仕様・規約・進捗管理ルールは **`CLAUDE.md`** に一元管理されています。
コードを生成する前に `CLAUDE.md` の内容を参照してください。

---

## Copilot 向けコード生成ヒント

### モデルのアソシエーション早見表

```ruby
Anime belongs_to :anime_series, optional: true
Anime has_many :songs, through: :anime_songs

Song belongs_to :artist
Song has_many :animes, through: :anime_songs
Song has_many :platform_links
Song has_many :reviews

Artist has_many :songs
# artist_type: person / unit / character
```

### enum の衝突回避（必須）

```ruby
# insert / reject は ActiveRecord のメソッドと衝突するため prefix 必須
enum :song_type, { op: 0, ed: 1, insert: 2, image: 3 }, prefix: :song
enum :action,    { approve: 0, reject: 1, flag: 2 },     prefix: :review
```

### 外部 API サービスの置き場所

| API | パス |
|-----|------|
| Annict (GraphQL) | `app/services/annict/` |
| Spotify | `app/services/spotify/` |
| AI 収集 | `app/services/ai/` |

環境変数: `ANNICT_API_TOKEN` / `SPOTIFY_CLIENT_ID` / `SPOTIFY_CLIENT_SECRET`
Spotify は 2026年2月の仕様変更あり。実装前に公式ドキュメントを確認すること。
