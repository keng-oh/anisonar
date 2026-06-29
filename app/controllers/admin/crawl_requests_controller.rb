module Admin
  class CrawlRequestsController < BaseController
    def destroy
      @crawl_request = CrawlRequest.find(params[:id])
      @crawl_request.destroy!
      redirect_to crawl_requests_admin_integrations_path(status: params[:status]), notice: "クロール依頼を削除しました"
    end
  end
end
