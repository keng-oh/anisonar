module CrawlRequests
  # クロール未依頼のアニメを視聴者数順に走査し、クロールキューへ追加する。
  # シリーズ所属アニメは別シーズンの情報混入を避けるため、シリーズ単位で1件にまとめる。
  class BulkEnqueueService
    def self.call(**kwargs)
      new(**kwargs).call
    end

    def initialize(limit:)
      @limit = limit
    end

    def call
      targets.map { |target| create_request(target) }
    end

    private

      def targets
        result = []
        candidates.each do |anime|
          target = anime.anime_series || anime
          next if result.include?(target)

          result << target
          break if result.size >= @limit
        end
        result
      end

      def candidates
        covered_series_ids = CrawlRequest.where.not(anime_series_id: nil).select(:anime_series_id)
        scope = Anime.where.missing(:crawl_requests)
                     .where("(wikipedia_url IS NOT NULL AND wikipedia_url != '') OR (official_site_url IS NOT NULL AND official_site_url != '')")

        scope.where(anime_series_id: nil)
             .or(scope.where.not(anime_series_id: covered_series_ids))
             .order(watchers_count: :desc)
             .limit(@limit * 20) # シリーズ単位に集約すると件数が減るため余裕を持って読む
      end

      def create_request(target)
        if target.is_a?(AnimeSeries)
          CrawlRequest.create!(anime_series: target, status: :pending)
        else
          CrawlRequest.create!(anime: target, status: :pending)
        end
      end
  end
end
