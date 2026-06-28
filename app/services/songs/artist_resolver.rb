module Songs
  # AiResearcher の出力（artist_name を含む items）を BulkSaveService 用の形式に変換する。
  #
  # 入力 item:  { title:, artist_name:, song_type: }
  # 出力 song_data:
  #   {
  #     title:, status:,
  #     notes: "[AI]",
  #     artist_id: Integer | "new",
  #     new_artist: { name:, artist_type:, status:, spotify_artist_id: } (artist_id == "new" のときのみ),
  #     anime_entries: [{ anime_id:, song_type: }]
  #   }
  class ArtistResolver
    def self.call(**kwargs)
      new(**kwargs).call
    end

    def initialize(items:, anime:, spotify_client: Spotify::Client.new)
      @items = items
      @anime = anime
      @spotify_client = spotify_client
    end

    def call
      @items.map { |item| build_song_data(item) }
    end

    private

      def build_song_data(item)
        match = resolve_artist(item[:artist_name])

        base = {
          title:  item[:title],
          status: :approved,
          notes:  "[AI]",
          anime_entries: [ { anime_id: @anime.id, song_type: item[:song_type] } ],
          series_entries: nil
        }

        case match
        when Artist
          base.merge(artist_id: match.id)
        else
          base.merge(artist_id: "new", new_artist: new_artist_attrs(item[:artist_name], spotify_artist_id: match&.fetch(:id, nil)))
        end
      end

      def new_artist_attrs(name, spotify_artist_id: nil)
        {
          name:              name.to_s.strip,
          artist_type:       "person",
          status:            "approved",
          spotify_artist_id: spotify_artist_id
        }
      end

      # Spotify Artist ID を最優先の重複判定キーとして使う。
      # Spotifyで完全一致しない場合のみ、ローカルの完全一致テキストマッチにフォールバックする
      # （部分一致フォールバックは無関係なアーティストへの誤結合を招くため使わない）。
      def resolve_artist(name)
        match = spotify_artist_match(name)
        return Artist.find_by(spotify_artist_id: match[:id]) || match if match

        find_existing_artist(name)
      end

      def spotify_artist_match(name)
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
        str.to_s.unicode_normalize(:nfkc).strip.downcase.gsub(/\s+/, " ")
      end
  end
end
