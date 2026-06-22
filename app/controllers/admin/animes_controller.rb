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

    def bulk_ai_song_research
      limit = (params[:limit].presence || 10).to_i.clamp(1, 100)
      animes = Anime.left_joins(:anime_songs)
                    .where(anime_songs: { id: nil })
                    .order(watchers_count: :desc)
                    .limit(limit)
      animes.each_with_index { |anime, i| AiSongResearchJob.set(wait: i * 30.seconds).perform_later(anime.id) }
      redirect_to admin_animes_path, notice: "#{animes.size} 件の楽曲取り込みをバックグラウンドで開始しました"
    end

    def bulk_cover_image_resolve
      limit = (params[:limit].presence || 20).to_i.clamp(1, 100)
      animes = Anime.where(cover_image_url: [ nil, "" ])
                    .order(watchers_count: :desc)
                    .limit(limit)
      animes.each_with_index { |anime, i| CoverImageResolveJob.set(wait: i * 2.seconds).perform_later(anime.id) }
      redirect_to admin_animes_path, notice: "#{animes.size} 件の画像取得を開始しました"
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
