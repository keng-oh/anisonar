module Admin
  class BaseController < ApplicationController
    before_action :authenticate_user!
    before_action :require_admin!
    before_action :set_pending_review_count

    layout "admin"

    private

      def require_admin!
        redirect_to root_path, alert: "管理者権限が必要です" unless current_user.admin?
      end

      def set_pending_review_count
        @pending_review_count = Song.pending_review.count
      end
  end
end
