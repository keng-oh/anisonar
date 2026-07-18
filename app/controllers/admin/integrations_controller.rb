module Admin
  class IntegrationsController < BaseController
    def cover_images
      @unresolved_animes = Anime.where(cover_image_url: [ nil, "" ])
                                .order(watchers_count: :desc)
                                .limit(100)
    end

    def crawl_requests
      @status = params[:status].presence || "pending"
      crawl_requests = CrawlRequest.includes(:anime, :anime_series).order(:created_at)
      crawl_requests = crawl_requests.where(status: @status) if @status != "all"

      @pagy, @crawl_requests = pagy(:offset, crawl_requests, limit: 20)
    end

    def bulk_enqueue_crawl_requests
      limit = (params[:limit].presence || 10).to_i.clamp(1, 50)
      created = CrawlRequests::BulkEnqueueService.call(limit: limit)
      redirect_to crawl_requests_admin_integrations_path, notice: "#{created.size} 件をクロールキューに追加しました"
    end

    def annict_sync
    end

    def create_annict_sync
      seasons = params[:seasons].presence&.split(",")&.map(&:strip)
      AnnictSyncJob.perform_later(seasons:)
      redirect_to annict_sync_admin_integrations_path, notice: "Annict 同期ジョブをキューに追加しました"
    end
  end
end
