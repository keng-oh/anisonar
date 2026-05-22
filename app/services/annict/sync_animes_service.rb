module Annict
  class SyncAnimesService
    WORKS_QUERY = <<~GQL
      query GetWorks($first: Int!, $after: String, $seasons: [String!]) {
        searchWorks(first: $first, after: $after, seasons: $seasons, orderBy: { field: SEASON, direction: DESC }) {
          nodes {
            annictId
            title
            titleEn
            media
            seasonYear
            seasonName
            image {
              recommendedImageUrl
            }
            seriesList(first: 1) {
              nodes {
                annictId
                name
                nameEn
              }
            }
          }
          pageInfo {
            hasNextPage
            endCursor
          }
        }
      }
    GQL

    MEDIA_TYPE_MAP = {
      "TV"    => :tv,
      "OVA"   => :ova,
      "MOVIE" => :movie,
      "WEB"   => :ona,
      "OTHER" => :special
    }.freeze

    SEASON_NAME_MAP = {
      "SPRING" => "spring",
      "SUMMER" => "summer",
      "FALL"   => "fall",
      "WINTER" => "winter"
    }.freeze

    def self.call(...)
      new(...).call
    end

    def initialize(client: Client.new, per_page: 50, seasons: nil)
      @client = client
      @per_page = per_page
      @seasons = seasons
    end

    def call
      cursor = nil
      synced = 0

      loop do
        variables = { first: @per_page, after: cursor, seasons: @seasons }
        data = @client.query(WORKS_QUERY, variables:)
        works_data = data["searchWorks"]

        works_data["nodes"].each { |node| sync_work(node) }
        synced += works_data["nodes"].size

        Rails.logger.info "[Annict] Synced #{synced} works..."

        page_info = works_data["pageInfo"]
        break unless page_info["hasNextPage"]

        cursor = page_info["endCursor"]
        sleep 0.5  # Annict API のレート制限を考慮
      end

      Rails.logger.info "[Annict] Done. Total: #{synced} works."
      synced
    end

    private

      def sync_work(node)
        series_node = node["seriesList"]["nodes"].first
        anime_series = sync_series(series_node)

        Anime.find_or_initialize_by(annict_id: node["annictId"].to_s).tap do |anime|
          anime.assign_attributes(
            title:           node["title"],
            title_en:        node["titleEn"].presence,
            media_type:      MEDIA_TYPE_MAP.fetch(node["media"], :special),
            season:          build_season(node["seasonYear"], node["seasonName"]),
            status:          infer_status(node["seasonYear"]),
            cover_image_url: node.dig("image", "recommendedImageUrl"),
            anime_series:
          )
          anime.save!
        end
      end

      def sync_series(node)
        return nil if node.nil?

        AnimeSeries.find_or_initialize_by(annict_series_id: node["annictId"].to_s).tap do |s|
          s.assign_attributes(name: node["name"], name_en: node["nameEn"].presence)
          s.save!
        end
      end

      def build_season(year, name)
        return nil if year.nil? || name.nil?

        "#{year}-#{SEASON_NAME_MAP[name]}"
      end

      # シーズン年が過去ならfinished、当年以降はairingとみなす（簡易推定）
      def infer_status(year)
        year.present? && year < Time.current.year ? :finished : :airing
      end
  end
end
