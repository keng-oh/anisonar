module Songs
  # トップページの棚に並べる曲。Spotify に紐づいた OP / ED を、使われているアニメの人気順（watchers_count）で返す
  #
  # - シリーズ共通の曲（series_songs）は、シリーズのアニメのうち最も人気のアニメの watchers_count で並べる
  # - 複数の作品で使われている曲は 1 回だけ、最も人気の作品の位置に出す（同じ人気なら OP を優先）
  #
  # 返す Song には次の属性が付く:
  #   shelf_song_type  "op" / "ed"
  #   shelf_work_title 表示する作品名（アニメのタイトル。シリーズ共通の曲はシリーズ名）
  #   shelf_anime_id / shelf_anime_series_id 作品へのリンク用（どちらか一方）
  #   shelf_popularity 並び順に使った watchers_count
  #   shelf_year       作品の放送年（animes.season の年。シリーズ共通の曲はシリーズ内で最も人気のアニメの season）
  #
  # year: を渡すと、その放送年の曲だけを返す（season の無い作品の曲は年では絞り込めないので出ない）
  class ShelfQuery
    SONG_TYPES = %w[op ed].freeze
    SONG_TYPE_VALUES = AnimeSong.song_types.values_at(*SONG_TYPES).join(", ")
    SONG_TYPE_NAME_WHENS = AnimeSong.song_types.slice(*SONG_TYPES).map { |name, value| "WHEN #{value} THEN '#{name}'" }.join(" ")

    # season は "2025-spring" や "2025-"（年のみ）。先頭の 4 桁を年とし、形が違えば NULL にする
    def self.year_sql(season_column) = "substring(#{season_column} from '^([0-9]{4})')::integer"

    ANIME_CANDIDATES_SQL = <<~SQL.squish
      SELECT anime_songs.song_id,
             anime_songs.song_type AS song_type_value,
             CASE anime_songs.song_type #{SONG_TYPE_NAME_WHENS} END AS song_type,
             animes.watchers_count AS popularity,
             animes.title AS work_title,
             animes.id AS anime_id,
             NULL::bigint AS anime_series_id,
             #{year_sql("animes.season")} AS year
      FROM anime_songs
      INNER JOIN animes ON animes.id = anime_songs.anime_id
      WHERE anime_songs.song_type IN (#{SONG_TYPE_VALUES})
    SQL

    # シリーズ共通の曲は、シリーズ内で最も人気のアニメの人気と放送年を使う
    SERIES_CANDIDATES_SQL = <<~SQL.squish
      SELECT series_songs.song_id,
             series_songs.song_type AS song_type_value,
             CASE series_songs.song_type #{SONG_TYPE_NAME_WHENS} END AS song_type,
             COALESCE(top_anime.watchers_count, 0) AS popularity,
             anime_series.name AS work_title,
             NULL::bigint AS anime_id,
             anime_series.id AS anime_series_id,
             #{year_sql("top_anime.season")} AS year
      FROM series_songs
      INNER JOIN anime_series ON anime_series.id = series_songs.anime_series_id
      LEFT JOIN LATERAL (
        SELECT animes.watchers_count, animes.season
        FROM animes
        WHERE animes.anime_series_id = anime_series.id
        ORDER BY animes.watchers_count DESC, animes.id ASC
        LIMIT 1
      ) top_anime ON true
      WHERE series_songs.song_type IN (#{SONG_TYPE_VALUES})
    SQL

    # 曲ごとに最も人気の作品を 1 件だけ残して songs に結合する
    SHELF_JOIN_SQL = <<~SQL.squish
      INNER JOIN (
        SELECT DISTINCT ON (candidates.song_id) candidates.*
        FROM (#{ANIME_CANDIDATES_SQL} UNION ALL #{SERIES_CANDIDATES_SQL}) candidates
        ORDER BY candidates.song_id, candidates.popularity DESC, candidates.song_type_value ASC
      ) shelf ON shelf.song_id = songs.id
    SQL

    def self.call(...) = new(...).call

    # 棚に曲がある放送年（新しい順）
    def self.years
      shelf_songs.where.not("shelf.year": nil).distinct.order(Arel.sql("shelf.year DESC")).pluck("shelf.year")
    end

    def self.shelf_songs
      Song.joins(SHELF_JOIN_SQL).where(id: PlatformLink.spotify.select(:song_id))
    end

    def initialize(year: nil)
      @year = year
    end

    def call
      songs = self.class.shelf_songs
        .select(
          "songs.*",
          "shelf.song_type AS shelf_song_type",
          "shelf.work_title AS shelf_work_title",
          "shelf.anime_id AS shelf_anime_id",
          "shelf.anime_series_id AS shelf_anime_series_id",
          "shelf.popularity AS shelf_popularity",
          "shelf.year AS shelf_year"
        )
        .order(Arel.sql("shelf.popularity DESC, songs.id ASC"))
      @year ? songs.where("shelf.year": @year) : songs
    end
  end
end
