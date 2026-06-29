module Admin
  class ArtistsController < BaseController
    def index
      artists = Artist.includes(:songs)
      artists = artists.search(params[:q]) if params[:q].present?
      artists = artists.where(spotify_artist_id: nil) if params[:spotify] == "unlinked"
      artists = artists.where.not(spotify_artist_id: nil) if params[:spotify] == "linked"
      artists = artists.order(sort_order)

      @pagy, @artists = pagy(:offset, artists, limit: 20)
    end

    private

      SORT_OPTIONS = {
        "newest" => { created_at: :desc },
        "oldest" => { created_at: :asc },
        "name"   => { name: :asc }
      }.freeze

      def sort_order
        SORT_OPTIONS.fetch(params[:sort], SORT_OPTIONS["newest"])
      end
  end
end
