module Api
  module N8n
    class CrawlRequestsController < BaseController
      # n8nワークフローがクロール対象を取得するためのポーリング用エンドポイント
      def index
        status = params[:status].presence || "pending"
        limit = (params[:limit].presence || 5).to_i.clamp(1, 50)

        crawl_requests = CrawlRequest.includes(:anime).where(status: status).order(:created_at).limit(limit)

        render json: crawl_requests.map { |cr|
          {
            id: cr.id,
            urls: [ cr.anime.wikipedia_url, cr.anime.official_site_url ].compact_blank,
            status: cr.status,
            error_message: cr.error_message,
            anime: { id: cr.anime.id, title: cr.anime.title }
          }
        }
      end

      # n8nがクロール/抽出の進行状況（status・Difyドキュメント連携結果など）を更新する
      def update
        crawl_request = CrawlRequest.find(params[:id])
        if crawl_request.update(crawl_request_params)
          render json: { id: crawl_request.id, status: crawl_request.status }
        else
          render json: { errors: crawl_request.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # n8nがAIで抽出した楽曲データ（曲名・アーティスト等）を受け取り、非同期で保存する。
      # アーティスト/楽曲のSpotify問い合わせを含むため、ジョブに積んで即時レスポンスする。
      # 実際の成否は GET /api/n8n/crawl_requests?status=done|failed をポーリングして確認する。
      def songs
        crawl_request = CrawlRequest.find(params[:id])
        items = params.expect(items: [ [ :title, :artist_name, :song_type ] ]).map(&:to_h)

        CrawlSongsImportJob.perform_later(crawl_request.id, items)
        render json: { queued: true }, status: :accepted
      end

      private

        def crawl_request_params
          params.permit(:status, :dify_document_id, :error_message)
        end
    end
  end
end
