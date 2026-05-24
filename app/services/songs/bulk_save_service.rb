module Songs
  class BulkSaveService
    Result = Data.define(:saved, :failed)

    # songs_data: Array of Hash
    #   title:             String (required)
    #   status:            String (default: "pending")
    #   notes:             String (optional)
    #   artist_id:         Integer | "new" (required)
    #   new_artist:        Hash (required when artist_id == "new")
    #     name:            String
    #     name_kana:       String (optional)
    #     artist_type:     String
    #     image_url:       String (optional)
    #     anime_id:        Integer (required when artist_type == "character")
    #   anime_entries:     Array of { anime_id:, song_type: }
    #     nil  → 既存の紐付けを保持
    #     []   → 全削除
    #     配列 → 差分マージ
    #   series_entries:    Array of { anime_series_id:, song_type: }（anime_entries と同様）
    def self.call(**kwargs)
      new(**kwargs).call
    end

    def initialize(songs_data:, user:)
      @songs_data = songs_data
      @user       = user
    end

    def call
      saved  = []
      failed = []

      @songs_data.each do |data|
        song = find_or_initialize(data)
        song.assign_attributes(
          title:  data[:title],
          status: data[:status] || :pending,
          notes:  data[:notes]
        )
        song.created_by_user ||= @user

        Songs::SaveService.call(
          song:              song,
          artist_id:         data[:artist_id].to_s,
          new_artist_params: data[:new_artist],
          anime_entries:     data[:anime_entries],
          series_entries:    data[:series_entries],
          user:              @user
        )

        if song.persisted? && song.errors.none?
          saved << song
        else
          failed << { data: data, song: song, messages: song.errors.full_messages }
        end
      end

      Result.new(saved: saved, failed: failed)
    end

    private

      def find_or_initialize(data)
        artist_id = data[:artist_id]
        if artist_id.present? && artist_id.to_s != "new"
          Song.find_or_initialize_by(title: data[:title], artist_id: artist_id)
        else
          Song.new
        end
      end
  end
end
