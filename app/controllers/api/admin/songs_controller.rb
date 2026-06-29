module Api
  module Admin
    class SongsController < BaseController
      def spotify_candidates
        song = Song.find(params[:id])
        query = %(track:"#{song.title}" artist:"#{song.artist.name}")
        tracks = Spotify::Client.new.search_track(query, limit: 5)

        render json: tracks.map { |t| candidate_json(t, artist_name: song.artist.name) }
      rescue Spotify::Client::Error => e
        render json: { error: e.message }, status: :bad_gateway
      end

      # 検索でうまく見つからない曲を、URL/トラックIDを直接指定して取得するための手動入力用
      def spotify_track
        song = Song.find(params[:id])
        track = Spotify::Client.new.get_track(params[:track_id])
        render json: candidate_json(track, artist_name: song.artist.name)
      rescue Spotify::Client::Error => e
        render json: { error: e.message }, status: :bad_gateway
      end

      private

        def candidate_json(track, artist_name:)
          album = track["album"] || {}
          matched_artist = track["artists"].find { |a| normalize(a["name"]) == normalize(artist_name) }
          {
            id: track["id"],
            name: track["name"],
            artists: track["artists"].map { |a| a["name"] }.join(", "),
            artist_spotify_id: matched_artist && matched_artist["id"],
            album_name: album["name"],
            album_platform_id: album["id"],
            album_image_url: album.dig("images", 0, "url"),
            album_release_date: album["release_date"],
            url: "https://open.spotify.com/track/#{track['id']}"
          }
        end

        # Songs::ArtistResolver と同じ正規化（空白除去）で表記揺れを吸収する
        def normalize(str)
          str.to_s.unicode_normalize(:nfkc).downcase.gsub(/\s+/, "")
        end
    end
  end
end
