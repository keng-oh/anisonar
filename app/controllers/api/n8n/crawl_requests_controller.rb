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

      # n8nがAIで抽出した楽曲データ（曲名・アーティスト等）を受け取り保存する
      def songs
        crawl_request = CrawlRequest.find(params[:id])
        items = params.expect(items: [ [ :title, :artist_name, :song_type, :source_url ] ])

        songs_data = Songs::ArtistResolver.call(items: items, anime: crawl_request.anime)
        result = Songs::BulkSaveService.call(songs_data: songs_data, user: User.ai_bot)

        if result.failed.empty?
          crawl_request.update!(status: :done)
          render json: { saved: result.saved.size, failed: 0 }
        else
          crawl_request.update!(status: :failed, error_message: result.failed.map { |f| f[:messages].join(", ") }.join("; "))
          render json: { saved: result.saved.size, failed: result.failed.size }, status: :unprocessable_entity
        end
      end

      private

        def crawl_request_params
          params.permit(:status, :dify_document_id, :error_message)
        end
    end
  end
end
