module CrawlRequests
  # 指定したアニメをクロールキューへ追加する。
  # シリーズ所属アニメは別シーズンの情報混入を避けるため、シリーズ単位で1件にまとめる。
  # すでに依頼のあるアニメ・シリーズ（状態は問わない）は追加しない。失敗した依頼のやり直しは管理画面の「やり直す」で行う。
  #
  # Wikipedia・公式サイトの URL が無くても追加する（n8n がタイトルで Wikipedia を検索するため）。
  class EnqueueService
    def self.call(...) = new(...).call

    # @param animes [Enumerable<Anime>] 並び順どおりに追加する
    # @param limit [Integer, nil] 追加する件数の上限（シリーズにまとめた後の件数）
    def initialize(animes:, limit: nil)
      @animes = animes
      @limit  = limit
    end

    # @return [Array<CrawlRequest>] 追加した依頼
    def call
      requested_anime_ids  = CrawlRequest.where.not(anime_id: nil).pluck(:anime_id).to_set
      requested_series_ids = CrawlRequest.where.not(anime_series_id: nil).pluck(:anime_series_id).to_set

      created = []
      @animes.each do |anime|
        break if @limit && created.size >= @limit

        if anime.anime_series_id
          next if requested_series_ids.include?(anime.anime_series_id)

          requested_series_ids << anime.anime_series_id
          created << CrawlRequest.create!(anime_series_id: anime.anime_series_id, status: :pending)
        else
          next if requested_anime_ids.include?(anime.id)

          requested_anime_ids << anime.id
          created << CrawlRequest.create!(anime: anime, status: :pending)
        end
      end
      created
    end
  end
end
