module Songs
  # AiResearcher の出力（artist_name を含む items）を BulkSaveService 用の形式に変換する。
  # アーティストの解決だけでなく、必要なら作成まで行い、常に実在する Artist の id を返す
  # （items 配列内に同じ新規アーティストの曲が複数あっても、作成は1回だけになるようにするため）。
  #
  # 入力 item:  { title:, artist_name:, song_type: }
  # 出力 song_data:
  #   {
  #     title:,
  #     notes: "[AI]",
  #     artist_id: Integer,
  #     anime_entries: [{ anime_id:, song_type: }]
  #   }
  class ArtistResolver
    def self.call(**kwargs)
      new(**kwargs).call
    end

    def initialize(items:, anime:, user: nil, spotify_client: Spotify::Client.new)
      @items = items
      @anime = anime
      @user = user
      @spotify_client = spotify_client
      @resolved_artists = {}
      @spotify_matches = {}
    end

    def call
      @items.map { |item| build_song_data(item) }
    end

    private

      def build_song_data(item)
        artist = resolve_or_create_artist(item[:artist_name])

        {
          title:  item[:title],
          notes:  "[AI]",
          artist_id: artist.id,
          anime_entries: [ { anime_id: @anime.id, song_type: item[:song_type] } ],
          series_entries: nil
        }
      end

      # Spotify Artist ID を最優先の重複判定キーとして使う。
      # Spotifyで完全一致しない場合、またspotify_artist_idで既存Artistが見つからない場合は、
      # 必ずローカルの完全一致テキストマッチも確認してから新規作成を判断する
      # （部分一致フォールバックは無関係なアーティストへの誤結合を招くため使わない）。
      # 同一バッチ内で同じアーティストに解決された曲は @resolved_artists でキャッシュし、
      # 重複作成・重複Spotify検索を防ぐ。
      def resolve_or_create_artist(name)
        match = spotify_artist_match(name)
        dedup_key = match ? "spotify:#{match[:id]}" : "name:#{normalize(name)}"

        @resolved_artists[dedup_key] ||=
          (match && Artist.find_by(spotify_artist_id: match[:id])) ||
          find_existing_artist(name) ||
          create_artist(name, spotify_artist_id: match&.fetch(:id, nil))
      end

      def create_artist(name, spotify_artist_id:)
        Artist.create!(
          name:              name.to_s.strip,
          artist_type:       "person",
          spotify_artist_id: spotify_artist_id,
          created_by_user:   @user,
          updated_by_user:   @user
        )
      rescue ActiveRecord::RecordInvalid
        # レースコンディション等で他から先に作成された場合は、それを再取得して使う
        existing = spotify_artist_id && Artist.find_by(spotify_artist_id: spotify_artist_id)
        existing || find_existing_artist(name) || raise
      end

      def spotify_artist_match(name)
        key = normalize(name)
        return @spotify_matches[key] if @spotify_matches.key?(key)

        @spotify_matches[key] = fetch_spotify_artist_match(name)
      end

      def fetch_spotify_artist_match(name)
        return nil if name.blank?

        results = @spotify_client.search_artist(name, limit: 5)
        exact = results.find { |a| normalize(a["name"]) == normalize(name) }
        exact && { id: exact["id"] }
      rescue Spotify::Client::Error => e
        Rails.logger.warn "[Songs::ArtistResolver] spotify lookup failed name=#{name} error=#{e.message}"
        nil
      end

      def find_existing_artist(name)
        normalized = normalize(name)
        return nil if normalized.blank?

        candidates = Artist
          .where("LOWER(name) ILIKE :q OR LOWER(COALESCE(name_kana, '')) ILIKE :q", q: "%#{Artist.sanitize_sql_like(normalized)}%")
          .limit(20)

        candidates.find { |a| normalize(a.name) == normalized } ||
          candidates.find { |a| a.name_kana.present? && normalize(a.name_kana) == normalized }
      end

      def normalize(str)
        NameNormalizer.call(str)
      end
  end
end
