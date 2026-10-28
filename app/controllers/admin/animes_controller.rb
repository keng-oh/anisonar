module Admin
  class AnimesController < BaseController
    BULK_ENQUEUE_LIMIT = 50

    def index
      animes = filtered_animes.includes(:anime_series, :anime_songs).order(sort_order)

      @pagy, @animes = pagy(:offset, animes, limit: 20)
      @crawl_statuses = crawl_statuses_for(@animes)
      @years = Anime.where.not(season: [ nil, "" ]).distinct.pluck(Arel.sql("split_part(season, '-', 1)")).compact_blank.sort.reverse
    end

    # チェックしたアニメ、または絞り込んだ結果（上から最大 BULK_ENQUEUE_LIMIT 件）をクロールキューへ追加する
    def bulk_enqueue_crawl_requests
      animes =
        if params[:scope] == "filtered"
          filtered_animes
        elsif params[:anime_ids].present?
          Anime.where(id: params[:anime_ids])
        else
          return redirect_back_or_to(admin_animes_path, alert: "クロール依頼するアニメを選んでください")
        end
      animes = animes.order(sort_order).limit(BULK_ENQUEUE_LIMIT * CrawlRequests::BulkEnqueueService::CANDIDATE_FACTOR)
      created = CrawlRequests::EnqueueService.call(animes: animes, limit: BULK_ENQUEUE_LIMIT)
      redirect_back_or_to admin_animes_path, notice: "#{created.size} 件をクロールキューに追加しました（依頼済みのものは除きました）"
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
      # URL が無くても n8n がタイトルで Wikipedia を検索するので、URL の有無は問わない
      crawl_request = CrawlRequests::EnqueueService.call(animes: [ anime ]).first
      if crawl_request
        redirect_to edit_admin_anime_path(anime), notice: "「#{crawl_request.target_label}」をクロールキューへ追加しました"
      else
        redirect_to edit_admin_anime_path(anime), alert: "このアニメ（またはシリーズ）はすでにクロール依頼があります"
      end
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

      CRAWL_FILTERS = {
        "none"    => ->(animes) { animes.without_crawl_request },
        "waiting" => ->(animes) { animes.with_crawl_status(%w[pending crawling]) },
        "done"    => ->(animes) { animes.with_crawl_status("done") },
        "failed"  => ->(animes) { animes.with_crawl_status("failed") }
      }.freeze

      def filtered_animes
        animes = Anime.all
        animes = animes.search(params[:q])                     if params[:q].present?
        animes = animes.where(media_type: params[:media_type]) if params[:media_type].present?
        animes = animes.where(status: params[:status])         if params[:status].present?
        animes = animes.by_year(params[:year])                 if params[:year].present?
        animes = animes.by_season_name(params[:season_name])   if params[:season_name].present?
        animes = animes.with_songs                             if params[:songs] == "with"
        animes = animes.where.not(id: Anime.with_songs.select(:id)) if params[:songs] == "without"
        animes = CRAWL_FILTERS[params[:crawl]].call(animes)    if CRAWL_FILTERS.key?(params[:crawl])
        animes
      end

      # 一覧の各アニメのクロール依頼（アニメ自身か、所属シリーズへの依頼）
      def crawl_statuses_for(animes)
        series_ids = animes.filter_map(&:anime_series_id)
        requests = CrawlRequest.where(anime_id: animes.map(&:id)).or(CrawlRequest.where(anime_series_id: series_ids)).to_a
        by_anime = requests.select(&:anime_id).index_by(&:anime_id)
        by_series = requests.select(&:anime_series_id).index_by(&:anime_series_id)
        animes.to_h { |a| [ a.id, (by_series[a.anime_series_id] if a.anime_series_id) || by_anime[a.id] ] }
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
