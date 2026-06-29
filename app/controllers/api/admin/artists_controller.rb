module Api
  module Admin
    class ArtistsController < BaseController
      def index
        artists = Artist.order(:name)
        if params[:q].present?
          q = "%#{Artist.sanitize_sql_like(params[:q])}%"
          artists = artists.where("name ILIKE :q OR name_kana ILIKE :q", q:)
        end
        render json: artists.limit(20).map { |a|
          { id: a.id, label: "#{a.name}（#{a.artist_type}）" }
        }
      end

      def spotify_candidates
        artist = Artist.find(params[:id])
        results = Spotify::Client.new.search_artist(artist.name, limit: 5)

        render json: results.map { |a| candidate_json(a) }
      rescue Spotify::Client::Error => e
        render json: { error: e.message }, status: :bad_gateway
      end

      # 検索でうまく見つからないアーティストを、URL/アーティストIDを直接指定して取得するための手動入力用
      def spotify_artist
        result = Spotify::Client.new.get_artist(params[:spotify_artist_id])
        render json: candidate_json(result)
      rescue Spotify::Client::Error => e
        render json: { error: e.message }, status: :bad_gateway
      end

      private

        def candidate_json(artist)
          {
            id: artist["id"],
            name: artist["name"],
            image_url: artist.dig("images", 0, "url"),
            url: "https://open.spotify.com/artist/#{artist['id']}"
          }
        end
    end
  end
end
