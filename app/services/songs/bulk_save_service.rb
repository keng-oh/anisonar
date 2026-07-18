module Songs
  class BulkSaveService
    Result = Data.define(:saved, :failed)

    # songs_data: Array of Hash
    #   title:             String (required)
    #   notes:             String (optional)
    #   artist_id:         Integer (required)
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
        song.title = data[:title]
        song.notes = data[:notes] if data.key?(:notes)
        song.created_by_user ||= @user

        # AI取り込み専用の経路のため additive（追加のみ）で保存し、
        # 既存曲の紐付け・song_type など人間による修正を上書きしない
        Songs::SaveService.call(
          song:           song,
          artist_id:      data[:artist_id],
          anime_entries:  data[:anime_entries],
          series_entries: data[:series_entries],
          user:           @user,
          additive:       true
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
        Song.find_or_initialize_by(title: data[:title], artist_id: data[:artist_id])
      end
  end
end
