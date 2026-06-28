module Songs
  class SaveService
    # anime_entries / series_entries:
    #   nil   → 既存の紐付けを触らない
    #   []    → 既存の紐付けを全削除
    #   配列  → 既存と差分マージ（同一 anime/series は song_type の変更のみ更新）
    def self.call(**kwargs)
      new(**kwargs).call
    end

    def initialize(song:, artist_id:, new_artist_params:, anime_entries:, series_entries:, user:)
      @song              = song
      @artist_id         = artist_id
      @new_artist_params = new_artist_params
      @anime_entries     = anime_entries
      @series_entries    = series_entries
      @user              = user
    end

    def call
      ApplicationRecord.transaction do
        artist = resolve_artist
        break unless artist

        @song.artist = artist
        @song.updated_by_user = @user

        raise ActiveRecord::Rollback unless @song.save

        reconcile_anime_songs
        reconcile_series_songs
      end

      @song
    end

    private

      def resolve_artist
        if @artist_id == "new"
          artist = Artist.new(@new_artist_params)
          artist.created_by_user ||= @user
          artist.updated_by_user = @user
          unless artist.save
            artist.errors.each { |e| @song.errors.add(:base, "アーティスト #{e.full_message}") }
            raise ActiveRecord::Rollback
          end
          artist
        else
          Artist.find_by(id: @artist_id)
        end
      end

      def reconcile_anime_songs
        return if @anime_entries.nil?

        desired = @anime_entries
          .reject { |e| e[:anime_id].blank? }
          .index_by { |e| e[:anime_id].to_i }
        existing = @song.anime_songs.index_by(&:anime_id)

        (existing.keys - desired.keys).each { |id| existing[id].destroy }

        desired.each do |anime_id, entry|
          type = entry[:song_type].presence || "op"
          if (record = existing[anime_id])
            record.update!(song_type: type) unless record.song_type == type
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

        (existing.keys - desired.keys).each { |id| existing[id].destroy }

        desired.each do |series_id, entry|
          type = entry[:song_type].presence || "op"
          if (record = existing[series_id])
            record.update!(song_type: type) unless record.song_type == type
          else
            @song.series_songs.create!(anime_series_id: series_id, song_type: type)
          end
        end
      end
  end
end
