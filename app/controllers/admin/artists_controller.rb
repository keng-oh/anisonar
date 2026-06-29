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

    def new
      @artist = Artist.new
    end

    def create
      @artist = Artist.new(artist_params)

      if @artist.save
        redirect_to edit_admin_artist_path(@artist), notice: "「#{@artist.name}」を登録しました"
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      @artist = Artist.find(params[:id])
    end

    def update
      @artist = Artist.find(params[:id])

      if @artist.update(artist_params)
        redirect_to admin_artists_path, notice: "「#{@artist.name}」を更新しました"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @artist = Artist.find(params[:id])
      name = @artist.name

      if @artist.songs.exists?
        redirect_to edit_admin_artist_path(@artist), alert: "「#{name}」には楽曲が紐づいているため削除できません"
      else
        @artist.destroy!
        redirect_to admin_artists_path, notice: "「#{name}」を削除しました"
      end
    end

    def spotify_link
      @artist = Artist.find(params[:id])
      attrs = { spotify_artist_id: params[:spotify_artist_id] }
      attrs[:image_url] = params[:image_url] if params[:image_url].present?
      @artist.update!(attrs)
      redirect_to edit_admin_artist_path(@artist), notice: "「#{@artist.name}」をSpotifyと連携しました"
    end

    private

      def artist_params
        params.expect(artist: [ :name, :name_kana, :artist_type, :anime_id, :image_url ])
      end

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
