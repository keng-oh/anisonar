module DataChecks
  class SpotifyNotFoundHeavyAnimes
    KEY = "spotify_not_found_heavy_animes"
    LABEL = "Spotify で見つからない曲が多い作品"
    DESCRIPTION = "Spotify と照合した曲が 3 曲以上あり、その半分以上が見つからない作品（抽出の誤りが多いことの目印）"

    # 照合済みの曲（紐づいた曲 + 見つからなかった曲）がこの数以上の作品だけを見る
    MIN_CHECKED = 3
    # 照合済みの曲のうち、見つからなかった曲の割合がこれ以上なら拾う
    MIN_RATIO = 0.5

    def self.call = new.call

    def call
      heavy(AnimeSong, :anime_id, Anime, :title) + heavy(SeriesSong, :anime_series_id, AnimeSeries, :name)
    end

    private

      def heavy(link_model, key, target_model, name_attr)
        linked = link_model.where(song_id: PlatformLink.spotify.select(:song_id)).group(key).distinct.count(:song_id)
        missing = link_model.where(song_id: Song.spotify_not_found.select(:id)).group(key).distinct.count(:song_id)

        ids = missing.keys.select do |id|
          checked = linked.fetch(id, 0) + missing[id]
          checked >= MIN_CHECKED && missing[id] >= checked * MIN_RATIO
        end
        target_model.where(id: ids).order(:id).map do |target|
          checked = linked.fetch(target.id, 0) + missing[target.id]
          Finding.new(record: target, label: target.public_send(name_attr), detail: "#{checked} 曲中 #{missing[target.id]} 曲が見つからない")
        end
      end
  end
end
