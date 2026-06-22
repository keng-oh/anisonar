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

      def best_match
        query = %(track:"#{@song.title}" artist:"#{@song.artist.name}")
        @client.search_track(query, limit: 5).first
      end
  end
end
