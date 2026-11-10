module DataChecks
  class DuplicateSongTitles
    KEY = "duplicate_song_titles"
    LABEL = "曲名の重複"
    DESCRIPTION = "同じアニメ（シリーズ）に、正規化した曲名が同じで別々に登録されている曲がある（アーティストが違うものは名義の取り違えの疑い）"

    def self.call = new.call

    def call
      details = Hash.new { |hash, song_id| hash[song_id] = [] }
      collect(AnimeSong, :anime_id, Anime, :title, details)
      collect(SeriesSong, :anime_series_id, AnimeSeries, :name, details)
      return [] if details.empty?

      songs = Song.includes(:artist).where(id: details.keys).index_by(&:id)
      details.keys.sort.map do |song_id|
        song = songs.fetch(song_id)
        Finding.new(record: song, label: song.title, detail: details[song_id].join(" / "))
      end
    end

    private

      # 紐づけ先（アニメまたはシリーズ）ごとに、正規化した曲名が同じ別の曲を探す
      def collect(link_model, target_column, target_model, target_attr, details)
        rows = link_model.joins(:song).pluck(target_column, "songs.id", "songs.title", "songs.artist_id").uniq
        groups = rows.group_by { |target_id, _song_id, title, _artist_id| [ target_id, NameNormalizer.call(title) ] }
        groups = groups.values.select { |members| members.map { |m| m[1] }.uniq.size > 1 }
        return if groups.empty?

        artist_names = Artist.where(id: groups.flatten(1).map(&:last)).pluck(:id, :name).to_h
        target_names = target_model.where(id: groups.map { |members| members.first[0] }).pluck(:id, target_attr).to_h

        groups.each do |members|
          members.each do |target_id, song_id, _title, _artist_id|
            members.each do |_, other_id, other_title, other_artist_id|
              next if other_id == song_id

              details[song_id] << "「#{other_title}」（#{artist_names[other_artist_id]}）と同名 — #{target_names[target_id]}"
            end
          end
        end
      end
  end
end
