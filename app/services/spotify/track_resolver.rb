module Spotify
  # 楽曲名 + アーティスト名で Spotify を検索し、最も一致するトラックを
  # PlatformLink (platform: :spotify) として保存する。
  class TrackResolver
    def self.call(...) = new(...).call

    def initialize(song:, client: Spotify::Client.new)
      @song   = song
      @client = client
    end

    def call
      track = best_match
      return nil unless track

      album = track["album"] || {}

      link = @song.platform_links.find_or_initialize_by(platform: :spotify)
      link.platform_track_id   = track["id"]
      link.album_platform_id   = album["id"]
      link.album_name          = album["name"]
      link.album_image_url     = album.dig("images", 0, "url")
      link.album_release_date  = album["release_date"]
      link.save!
      link
    end

    private

      # 検索結果の artists 配列を、spotify_artist_id（無ければ正規化名）で検証してから採用する。
      # 曲名は表記揺れ・カバー・ライブ版などで誤マッチしやすいため、確信が持てない場合は nil を返す。
      def best_match
        query = %(track:"#{@song.title}" artist:"#{@song.artist.name}")
        candidates = @client.search_track(query, limit: 5)

        if @song.artist.spotify_artist_id.present?
          candidates.find { |t| t["artists"].any? { |a| a["id"] == @song.artist.spotify_artist_id } }
        else
          normalized_artist = normalize(@song.artist.name)
          candidates.find { |t| t["artists"].any? { |a| normalize(a["name"]) == normalized_artist } }
        end
      end

      def normalize(str)
        str.to_s.unicode_normalize(:nfkc).downcase.gsub(/\s+/, "")
      end
  end
end
