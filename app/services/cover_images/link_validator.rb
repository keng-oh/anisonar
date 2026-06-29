module CoverImages
  # cover_image_url の到達可能性を検証し、無効なものを nil にクリアする。
  # Annict の recommendedImageUrl は放送終了後に閉鎖された公式サイトの OGP 画像である
  # ことが多く、リンクは保存されているが実際には 404 等で取得不可なケースがある。
  class LinkValidator
    def self.call(...) = new(...).call

    def initialize(batch_size: 50)
      @conn = Faraday.new do |f|
        f.options.timeout = 8
        f.options.open_timeout = 5
      end
      @batch_size = batch_size
    end

    # @return [Array<Integer>] cover_image_url をクリアした Anime の id 一覧
    def call
      cleared_ids = []

      Anime.where.not(cover_image_url: [ nil, "" ]).find_each(batch_size: @batch_size) do |anime|
        next if reachable?(anime.cover_image_url)

        anime.update!(cover_image_url: nil)
        cleared_ids << anime.id
      end

      cleared_ids
    end

    private

      def reachable?(url, redirects_left: 3)
        return false if redirects_left.negative?

        res = @conn.head(url)

        case res.status
        when 200..299 then true
        when 300..399
          location = res.headers["location"]
          location.present? && reachable?(URI.join(url, location).to_s, redirects_left: redirects_left - 1)
        else
          false
        end
      rescue Faraday::Error, URI::Error
        false
      end
  end
end
