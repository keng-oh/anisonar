module Admin
  class AnimesController < BaseController
    def index
      animes = Anime.includes(:anime_series, :anime_songs)
      animes = animes.search(params[:q])               if params[:q].present?
      animes = animes.where(media_type: params[:media_type]) if params[:media_type].present?
      animes = animes.where(status: params[:status])   if params[:status].present?
      animes = animes.order(sort_order)

      @pagy, @animes = pagy(:offset, animes, limit: 20)
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

    def enqueue_crawl_request
      anime = Anime.find(params[:id])
      # シリーズ所属アニメは別シーズンの情報混入を避けるため、シリーズ単位でまとめてクロールする
      crawl_request = CrawlRequest.new(
        anime_series: anime.anime_series,
        anime: anime.anime_series ? nil : anime,
        status: :pending
      )
      if crawl_request.target_urls.empty?
        redirect_to edit_admin_anime_path(anime), alert: "クロール対象URL（Wikipedia/公式サイト）が未設定です"
        return
      end
      crawl_request.save!
      redirect_to edit_admin_anime_path(anime), notice: "「#{crawl_request.target_label}」をクロールキューへ追加しました"
    end

    def bulk_cover_image_resolve
      limit = (params[:limit].presence || 20).to_i.clamp(1, 100)
      animes = Anime.where(cover_image_url: [ nil, "" ])
                    .order(watchers_count: :desc)
                    .limit(limit)
      animes.each_with_index { |anime, i| CoverImageResolveJob.set(wait: i * 2.seconds).perform_later(anime.id) }
      redirect_to cover_images_admin_integrations_path, notice: "#{animes.size} 件の画像取得を開始しました"
    end

    private

      def anime_params
        params.expect(anime: [ :title, :title_en, :media_type, :status, :season, :cover_image_url ])
      end

      SORT_OPTIONS = {
        "popularity" => { watchers_count: :desc, season: :desc },
        "season"     => { season: :desc, title: :asc },
        "title"      => { title: :asc }
      }.freeze

      def sort_order
        SORT_OPTIONS.fetch(params[:sort], SORT_OPTIONS["popularity"])
      end
  end
end
