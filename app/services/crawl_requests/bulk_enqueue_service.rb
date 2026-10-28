module CrawlRequests
  # クロール未依頼のアニメを選んで、クロールキューへ追加する。
  #
  # strategy:
  #   :popular 視聴者数の多い順
  #   :recent  去年から今のシーズンまでに放送したアニメを、視聴者数の多い順（放送前のアニメは主題歌の情報が無いので除く）
  class BulkEnqueueService
    STRATEGIES = %i[popular recent].freeze
    # シリーズ単位にまとめると件数が減り、依頼済みのものも読み飛ばすため、上限より多めに読む
    CANDIDATE_FACTOR = 20

    def self.call(...) = new(...).call

    def initialize(limit:, strategy: :popular, today: Date.current)
      raise ArgumentError, "unknown strategy: #{strategy}" unless STRATEGIES.include?(strategy.to_sym)

      @limit    = limit
      @strategy = strategy.to_sym
      @today    = today
    end

    # @return [Array<CrawlRequest>] 追加した依頼
    def call
      CrawlRequests::EnqueueService.call(animes: candidates, limit: @limit)
    end

    private

      def candidates
        scope = Anime.without_crawl_request
        scope = scope.where(season: Anime.seasons_until(@today, years: 2)) if @strategy == :recent
        scope.order(watchers_count: :desc, id: :asc).limit(@limit * CANDIDATE_FACTOR)
      end
  end
end
