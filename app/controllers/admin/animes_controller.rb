module Admin
  class AnimesController < BaseController
    def index
      animes = Anime.includes(:anime_series).order(season: :desc, title: :asc)
      animes = animes.search(params[:q]) if params[:q].present?
      @animes = animes
    end

    def edit
      @anime = Anime.find(params[:id])
    end

    def update
      @anime = Anime.find(params[:id])
      if @anime.update(anime_params)
        redirect_to admin_animes_path, notice: "更新しました"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

      def anime_params
        params.expect(anime: [ :title, :title_en, :media_type, :status, :season ])
      end
  end
end
