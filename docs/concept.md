# アニソンDB サービス仕様書

## 1. サービス概要

アニメ作品に紐づく楽曲情報（OP・ED・挿入歌・イメージソング）を網羅的に管理・検索できるデータベースサービス。楽曲データそのものを資産として、Spotifyなどのストリーミングサービスとのプレイリスト連携機能も提供する。

### ターゲットユーザー

- アニメファン（一般ユーザー）
- アニソンデータを活用したい外部サービス・企業（BtoB API）

### 収益モデル（将来）

- BtoB API課金（月1〜5万円 × 複数社）
- プレミアム機能課金
- ストリーミングサービスへのアフィリエイト

---

## 2. 技術スタック

| 領域           | 技術                               |
| -------------- | ---------------------------------- |
| Backend        | Ruby on Rails（通常モード）        |
| Database       | PostgreSQL                         |
| 非同期ジョブ   | Sidekiq                            |
| Frontend       | Hotwire（Turbo + Stimulus）        |
| JS             | Alpine.js                          |
| CSS            | Tailwind CSS + daisyUI             |
| コンポーネント | ViewComponent                      |
| 外部API        | Annict API（GraphQL）、Spotify API |

---

## 3. データソース

### Annict API

- GraphQL APIでアニメ・シリーズ・エピソード情報を取得
- 取得できる主なフィールド：`title` / `seasonYear` / `seasonName` / `mediaType` / `seriesList`
- 楽曲情報はAnnictには含まれないため別途収集が必要

### 楽曲データ収集フロー

```
AIがWikipedia等をウェブ検索して楽曲情報を収集
　↓
仮登録（status: pending）
　↓
コミュニティレビュー（承認 / 否認投票）
　↓
自動承認条件を満たしたら本登録（status: approved）
または管理者が手動承認
　↓
同時にSpotify / Amazon Music / Apple Music の楽曲IDを紐付け
```

### Spotify API

- 曲名・アーティスト名で検索してTrack IDを取得
- 取得できる主なフィールド：`id` / `name` / `artists` / `album` / `popularity` / `preview_url`
- 2026年2月のAPI変更で一部エンドポイントが削除・変更されているため最新仕様を要確認

---

## 4. DBスキーマ

```
anime_series（シリーズ）
├── id
├── annict_series_id
├── name
└── name_en

animes（作品）
├── id
├── annict_id
├── anime_series_id     # nullable
├── title
├── title_en
├── season              # 例: 2024-spring
├── media_type          # tv / movie / ova / ona / special
├── series_order        # シリーズ内順番
├── status              # airing / finished
└── cover_image_url

artists（アーティスト）
├── id
├── name
├── name_kana
├── artist_type         # person / unit / character
├── anime_id            # character時のみ、nullable
└── image_url

artist_relations（アーティスト間の紐づけ）
├── id
├── from_artist_id      # 声優（person）
├── to_artist_id        # ユニット or キャラクター
└── relation_type       # member_of / voice_of

songs（楽曲）
├── id
├── title
├── artist_id
├── song_type           # OP / ED / INSERT / IMAGE
├── status              # pending / approved / rejected / reviewing
├── registered_by       # user_id or "ai"
├── approve_count
├── reject_count
├── last_reviewed_at
└── notes

anime_songs（アニメと楽曲の中間）
├── id
├── anime_id
├── song_id
├── song_type           # OP1 / ED2 など
└── episode_range       # 例: 1-12話

platform_links（配信プラットフォーム紐づけ）
├── id
├── song_id
├── platform            # spotify / amazon_music / apple_music
└── platform_track_id

users
├── id
├── email
├── role                # general / reviewer / admin
└── trusted_count       # 承認実績数

reviews（レビュー）
├── id
├── song_id
├── user_id
├── action              # approve / reject / flag
├── weight              # 投票の重み（trusted_count由来）
└── comment

auto_approval_settings（自動承認設定）
├── id
├── min_approve_count   # 最低承認票数
├── min_approve_rate    # 最低承認率（例: 0.7）
└── updated_at
```

### アーティストの種別について

声優・ユニット・キャラクターの3種を`artist_type`で管理し、`artist_relations`で相互に紐づける。

```
例）
水瀬いのり（person）
  └ voice_of → 紡木咲（character）
  └ member_of → i☆Ris（unit）
```

キャラクターは出演アニメを`anime_id`で直接持つ。

---

## 5. 自動承認ロジック

```
レビュー投票が来るたびに集計
　↓
approve_count >= min_approve_count
　かつ approve率 >= min_approve_rate
　かつ flagなし
　↓
status を approved に自動更新

承認後もflag / rejectが閾値を超えたら
status を reviewing に差し戻し
```

### 信頼度スコア（weight）

| ユーザー種別     | 投票の重み |
| ---------------- | ---------- |
| 新規ユーザー     | 1票        |
| 実績ありユーザー | 2票        |
| reviewer権限     | 3票        |

`auto_approval_settings`テーブルで閾値を管理することでコード変更なしに調整可能。

---

## 6. 必要な画面

### 一般ユーザー向け

- トップ / 検索ページ
- アニメ詳細ページ（関連楽曲一覧）
- 楽曲詳細ページ（プラットフォームリンク・プレイリスト追加）
- アーティスト詳細ページ
- マイプレイリストページ（Spotify連携）

### データ登録・レビュー系

- 楽曲登録フォーム（ユーザー手動登録）
- レビューキュー（仮登録データの一覧）
- レビュー詳細（承認 / 否認）

### 管理系

- 管理ダッシュボード
- ユーザー管理（役割変更）
- AI収集ジョブの実行・ログ確認

### 画面遷移のメインフロー

```
トップ（検索）
　↓ アニメ名で検索
アニメ詳細
　↓ 楽曲をクリック
楽曲詳細
　↓ Spotify連携済みなら
プレイリストに追加
```

---

## 7. MVPスコープ

### MVPの目的

**「アニメから関連楽曲を調べてSpotifyで聴ける」最小限の体験を届ける**

### 含めるもの

- Annict APIからアニメ情報を取得・同期
- AIによる楽曲情報の収集・仮登録
- 管理者による手動承認
- アニメ検索画面
- アニメ詳細画面（関連楽曲一覧）
- 楽曲詳細画面（Spotifyリンク）
- 管理者向けレビューキュー

### 含めないもの（後回し）

- ユーザー登録 / コミュニティレビュー
- 自動承認ロジック
- プレイリスト作成機能
- Amazon Music / Apple Music連携
- アーティスト詳細ページ
- API公開

### 推奨リリーススケジュール

```
1ヶ月目：DBスキーマ・Annict同期・管理画面
2ヶ月目：AI収集パイプライン・Spotify連携
3ヶ月目：一般公開
```

---

## 8. 開発方針

- 仕事と並行しながら開発（週10〜15時間目安）
- 完成より早期リリースを優先（3ヶ月以内に公開）
- 受託は行わず、プロダクト単体で収益化を目指す
- 将来的にBtoB APIとしてデータを外部提供することも視野に入れる
