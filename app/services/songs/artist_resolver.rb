module Songs
  # AiResearcher の出力（artist_name を含む items）を BulkSaveService 用の形式に変換する。
  #
  # 入力 item:  { title:, artist_name:, song_type:, source_url: }
  # 出力 song_data:
  #   {
  #     title:, status:,
  #     notes: "[AI] source_url",
  #     artist_id: Integer | "new",
  #     new_artist: { name:, artist_type: } (artist_id == "new" のときのみ),
  #     anime_entries: [{ anime_id:, song_type: }]
  #   }
  class ArtistResolver
    def self.call(**kwargs)
      new(**kwargs).call
    end

    def initialize(items:, anime:)
      @items = items
      @anime = anime
    end

    def call
      @items.map { |item| build_song_data(item) }
    end

    private

      def build_song_data(item)
        artist = find_existing_artist(item[:artist_name])

        base = {
          title:  item[:title],
          status: :pending,
          notes:  notes_for(item),
          anime_entries: [ { anime_id: @anime.id, song_type: item[:song_type] } ],
          series_entries: nil
        }

        if artist
          base.merge(artist_id: artist.id)
        else
          base.merge(
            artist_id:  "new",
            new_artist: {
              name:        item[:artist_name].to_s.strip,
              artist_type: "person"
            }
          )
        end
      end

      def find_existing_artist(name)
        normalized = normalize(name)
        return nil if normalized.blank?

        # 完全一致（正規化後）優先 → 部分一致フォールバック
        candidates = Artist
          .where("LOWER(name) ILIKE :q OR LOWER(COALESCE(name_kana, '')) ILIKE :q", q: "%#{Artist.sanitize_sql_like(normalized)}%")
          .limit(20)

        candidates.find { |a| normalize(a.name) == normalized } ||
          candidates.find { |a| a.name_kana.present? && normalize(a.name_kana) == normalized } ||
          candidates.first
      end

      def normalize(str)
        str.to_s.unicode_normalize(:nfkc).strip.downcase.gsub(/\s+/, " ")
      end

      def notes_for(item)
        item[:source_url].present? ? "[AI] #{item[:source_url]}" : "[AI]"
      end
  end
end
