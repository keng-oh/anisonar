module Admin
  class IntegrationsController < BaseController
    def cover_images
    end

    def spotify
    end

    def crawl_requests
      @crawl_requests = CrawlRequest.includes(:anime).order(created_at: :desc).limit(50)
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
