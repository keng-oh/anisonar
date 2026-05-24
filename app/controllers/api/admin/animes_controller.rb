module Api
  module Admin
    class AnimesController < BaseController
      def index
        animes = Anime.order(season: :desc, title: :asc)
        animes = animes.search(params[:q]) if params[:q].present?
        render json: animes.limit(30).map { |a|
          { id: a.id, title: a.title, season: a.season }
        }
      end
    end
  end
end
