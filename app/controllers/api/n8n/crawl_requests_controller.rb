module Api
  module N8n
    class CrawlRequestsController < BaseController
      # n8nワークフローがクロール対象を取得するためのポーリング用エンドポイント
      def index
        status = params[:status].presence || "pending"
        limit = (params[:limit].presence || 5).to_i.clamp(1, 50)

        crawl_requests = CrawlRequest.includes(:anime, anime_series: :animes).where(status: status).order(:created_at).limit(limit)

        # シリーズ依頼では複数シーズンの情報が混在したページを渡すため、
        # n8n(AI)側が楽曲をどのシーズンに帰属させるか判断できるよう animes 一覧を添える
        render json: crawl_requests.map { |cr|
          {
            id: cr.id,
            urls: cr.target_urls,
            status: cr.status,
            error_message: cr.error_message,
            anime_series: cr.anime_series && { id: cr.anime_series.id, name: cr.anime_series.name },
            animes: cr.target_animes.map { |a|
              {
                id: a.id,
                title: a.title,
                season: a.season,
                season_label: Anime.season_label(a.season),
                series_order: a.series_order
              }
            }
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
      # anime_id は index で渡した animes のいずれか。シリーズ依頼で判別不能な曲は
      # anime_id を省略するとシリーズ共通曲（series_songs）として保存される。
      # アーティスト/楽曲のSpotify問い合わせを含むため、ジョブに積んで即時レスポンスする。
      # 実際の成否は GET /api/n8n/crawl_requests?status=done|failed をポーリングして確認する。
      def songs
        crawl_request = CrawlRequest.find(params[:id])
        items = params.permit(items: [ :title, :artist_name, :song_type, :anime_id ]).fetch(:items, []).map(&:to_h)

        # 楽曲が1件も抽出できなかった場合も正常系として完了させる（依頼が crawling のまま残るのを防ぐ）
        if items.empty?
          crawl_request.update!(status: :done)
          render json: { queued: false }, status: :accepted
        else
          CrawlSongsImportJob.perform_later(crawl_request.id, items)
          render json: { queued: true }, status: :accepted
        end
      end

      private

        def crawl_request_params
          params.permit(:status, :dify_document_id, :error_message)
        end
    end
  end
end
