module Admin
  class AnimesController < BaseController
    def index
      animes = Anime.includes(:anime_series, :anime_songs)
      animes = animes.search(params[:q])               if params[:q].present?
      animes = animes.where(media_type: params[:media_type]) if params[:media_type].present?
      animes = animes.where(status: params[:status])   if params[:status].present?
      @animes = animes.order(sort_order)
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

    def ai_song_research
      anime = Anime.find(params[:id])
      AiSongResearchJob.perform_later(anime.id)
      redirect_to edit_admin_anime_path(anime), notice: "「#{anime.title}」の楽曲取り込みをバックグラウンドで開始しました"
    end

    private

      def anime_params
        params.expect(anime: [ :title, :title_en, :media_type, :status, :season ])
      end

      SORT_OPTIONS = {
        "popularity" => { watchers_count: :desc, season: :desc },
        "season"     => { season: :desc, title: :asc },
        "title"      => { title: :asc }
      }.freeze

      def sort_order
        SORT_OPTIONS.fetch(params[:sort], SORT_OPTIONS["season"])
      end
  end
end
