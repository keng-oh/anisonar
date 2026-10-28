module Admin
  class CrawlRequestsController < BaseController
    # 失敗した依頼を処理待ちに戻し、n8n にやり直させる
    def retry
      @crawl_request = CrawlRequest.find(params[:id])
      @crawl_request.update!(status: :pending, error_message: nil)
      redirect_to crawl_requests_admin_integrations_path(status: params[:status]), notice: "「#{@crawl_request.target_label}」を処理待ちに戻しました"
    end

    def destroy
      @crawl_request = CrawlRequest.find(params[:id])
      @crawl_request.destroy!
      redirect_to crawl_requests_admin_integrations_path(status: params[:status]), notice: "クロール依頼を削除しました"
    end
  end
end
