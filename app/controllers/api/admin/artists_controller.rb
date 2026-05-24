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
    end
  end
end
