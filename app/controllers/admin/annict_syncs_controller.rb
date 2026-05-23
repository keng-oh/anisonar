module Admin
  class AnnictSyncsController < BaseController
    def new
    end

    def create
      seasons = params[:seasons].presence&.split(",")&.map(&:strip)
      AnnictSyncJob.perform_later(seasons:)
      redirect_to new_admin_annict_sync_path, notice: "Annict 同期ジョブをキューに追加しました"
    end
  end
end
