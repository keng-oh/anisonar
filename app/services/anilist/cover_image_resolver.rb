module Anilist
  # アニメタイトルで AniList を検索し、カバー画像 URL を anime.cover_image_url に保存する。
  class CoverImageResolver
    def self.call(...) = new(...).call

    def initialize(anime:, client: Anilist::Client.new)
      @anime  = anime
      @client = client
    end

    def call
      media = @client.search_media(@anime.title)
      image_url = media&.dig("coverImage", "extraLarge").presence || media&.dig("coverImage", "large").presence
      return nil if image_url.blank?

      @anime.update!(cover_image_url: image_url)
      image_url
    end
  end
end
