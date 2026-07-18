module Songs
  class SaveService
    # anime_entries / series_entries:
    #   nil   → 既存の紐付けを触らない
    #   []    → 既存の紐付けを全削除
    #   配列  → 既存と差分マージ（同一 anime/series は song_type の変更のみ更新）
    #
    # additive: true（AI取り込み用）の場合は「無い紐付けの追加」だけを行う。
    # 既存の紐付け・song_type・updated_by_user には触れず、人間による修正をAIが巻き戻さないようにする。
    def self.call(**kwargs)
      new(**kwargs).call
    end

    def initialize(song:, artist_id:, anime_entries:, series_entries:, user:, additive: false)
      @song           = song
      @artist_id      = artist_id
      @anime_entries  = anime_entries
      @series_entries = series_entries
      @user           = user
      @additive       = additive
    end

    def call
      ApplicationRecord.transaction do
        artist = Artist.find_by(id: @artist_id)
        break unless artist

        @song.artist = artist
        @song.updated_by_user = @user unless @additive && @song.persisted?

        raise ActiveRecord::Rollback unless @song.save

        reconcile_anime_songs
        reconcile_series_songs
      end

      @song
    end

    private

      def reconcile_anime_songs
        return if @anime_entries.nil?

        desired = @anime_entries
          .reject { |e| e[:anime_id].blank? }
          .index_by { |e| e[:anime_id].to_i }
        existing = @song.anime_songs.index_by(&:anime_id)

        (existing.keys - desired.keys).each { |id| existing[id].destroy } unless @additive

        desired.each do |anime_id, entry|
          type = entry[:song_type].presence || "op"
          if (record = existing[anime_id])
            record.update!(song_type: type) unless @additive || record.song_type == type
          else
            @song.anime_songs.create!(anime_id: anime_id, song_type: type)
          end
        end
      end

      def reconcile_series_songs
        return if @series_entries.nil?

        desired = @series_entries
          .reject { |e| e[:anime_series_id].blank? }
          .index_by { |e| e[:anime_series_id].to_i }
        existing = @song.series_songs.index_by(&:anime_series_id)

        (existing.keys - desired.keys).each { |id| existing[id].destroy } unless @additive

        desired.each do |series_id, entry|
          type = entry[:song_type].presence || "op"
          if (record = existing[series_id])
            record.update!(song_type: type) unless @additive || record.song_type == type
          else
            @song.series_songs.create!(anime_series_id: series_id, song_type: type)
          end
        end
      end
  end
end
