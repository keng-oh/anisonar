module Admin
  class ArtistsController < BaseController
    def index
      artists = Artist.includes(:songs)
      artists = artists.search(params[:q]) if params[:q].present?
      artists = artists.where(spotify_artist_id: nil) if params[:spotify] == "unlinked"
      artists = artists.where.not(spotify_artist_id: nil) if params[:spotify] == "linked"
      artists = artists.joint if params[:joint] == "joint"
      artists = artists.unsplit_joint_candidates if params[:joint] == "unsplit"
      artists = filter_by_type(artists)
      artists = params[:sort] == "songs_count" ? artists.order_by_songs_count : artists.order(sort_order)

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
      @artist = Artist.includes(
        :credit_members, :joint_credits,
        voiced_character_relations: :to_artist, voice_actor_relations: :from_artist,
        unit_relations: :to_artist, unit_member_relations: :from_artist
      ).find(params[:id])
      @animes = Anime.where(id: AnimeSong.where(song_id: @artist.songs.select(:id)).select(:anime_id)).order(:title)
    end

    def update
      @artist = Artist.find(params[:id])

      if @artist.update(artist_params)
        redirect_to return_to_list_path(admin_artists_path), notice: "「#{@artist.name}」を更新しました"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @artist = Artist.find(params[:id])
      name = @artist.name

      if @artist.songs.exists?
        redirect_to edit_admin_artist_path(@artist, return_to: params[:return_to].presence), alert: "「#{name}」には楽曲が紐づいているため削除できません"
      else
        @artist.destroy!
        redirect_to return_to_list_path(admin_artists_path), notice: "「#{name}」を削除しました"
      end
    end

    def spotify_link
      @artist = Artist.find(params[:id])
      attrs = { spotify_artist_id: params[:spotify_artist_id] }
      attrs[:image_url] = params[:image_url] if params[:image_url].present?
      if @artist.update(attrs)
        redirect_to edit_admin_artist_path(@artist, return_to: params[:return_to].presence), notice: "「#{@artist.name}」をSpotifyと連携しました"
      else
        redirect_to edit_admin_artist_path(@artist, return_to: params[:return_to].presence), alert: @artist.errors.full_messages.to_sentence
      end
    end

    private

      def artist_params
        params.expect(artist: [ :name, :name_kana, :artist_type, :anime_id, :image_url ])
      end

      # voice_actor は種別ではなく、voice_of を持つ person
      def filter_by_type(artists)
        type = params[:artist_type].to_s
        return artists.voice_actors_only if type == "voice_actor"

        Artist.artist_types.key?(type) ? artists.where(artist_type: type) : artists
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
