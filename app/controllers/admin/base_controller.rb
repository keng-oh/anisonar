module Admin
  class BaseController < ApplicationController
    before_action :authenticate_user!
    before_action :require_admin!

    layout "admin"

    private

      def require_admin!
        redirect_to root_path, alert: "管理者権限が必要です" unless current_user.admin?
      end
  end
end
