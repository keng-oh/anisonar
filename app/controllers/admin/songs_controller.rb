module Admin
  class SongsController < BaseController
    def all
      songs = Song.includes(:artist, anime_songs: :anime)
      songs = songs.search(params[:q]) if params[:q].present?
      songs = songs.left_joins(:platform_links).where(platform_links: { id: nil }) if params[:platform] == "unlinked"
      songs = songs.order(sort_order)

      @pagy, @songs = pagy(:offset, songs, limit: 20)
    end

    def new
      @song = Song.new
    end

    def create
      @song = Song.new(song_params)
      @song.created_by_user = current_user

      Songs::SaveService.call(**service_params)

      if @song.persisted?
        redirect_to all_admin_songs_path, notice: "「#{@song.title}」を登録しました"
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      @song = Song.find(params[:id])
    end

    def update
      @song = Song.find(params[:id])
      @song.assign_attributes(song_params)

      Songs::SaveService.call(**service_params)

      if @song.errors.none?
        redirect_to all_admin_songs_path, notice: "「#{@song.title}」を更新しました"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def spotify_link
      song = Song.find(params[:id])
      link = song.platform_links.find_or_initialize_by(platform: :spotify)
      link.assign_attributes(spotify_link_params)
      link.save!
      backfill_artist_spotify_id(song.artist, params[:artist_spotify_id])
      redirect_to edit_admin_song_path(song), notice: "「#{song.title}」をSpotifyと連携しました"
    end

    private

      SORT_OPTIONS = {
        "newest" => { created_at: :desc },
        "oldest" => { created_at: :asc },
        "title"  => { title: :asc }
      }.freeze

      def sort_order
        SORT_OPTIONS.fetch(params[:sort], SORT_OPTIONS["newest"])
      end

      def song_params
        params.expect(song: [ :title, :notes ])
      end

      def service_params
        {
          song:               @song,
          artist_id:          params.dig(:song, :artist_id),
          new_artist_params:  inline_artist_params,
          anime_entries:      params.dig(:song, :anime_entries)  || [],
          series_entries:     params.dig(:song, :series_entries) || [],
          user:               current_user
        }
      end

      def inline_artist_params
        params.expect(song: { new_artist: [ :name, :name_kana, :artist_type, :image_url, :anime_id ] })[:new_artist]
      end

      def spotify_link_params
        params.permit(:platform_track_id, :album_platform_id, :album_name, :album_image_url, :album_release_date)
      end

      # 選んだトラックのアーティスト情報で、まだ spotify_artist_id が無いアーティストにだけ補完する
      def backfill_artist_spotify_id(artist, spotify_artist_id)
        return if spotify_artist_id.blank? || artist.spotify_artist_id.present?

        artist.update!(spotify_artist_id: spotify_artist_id)
      rescue ActiveRecord::RecordInvalid => e
        Rails.logger.warn "[Admin::SongsController] failed to backfill spotify_artist_id=#{spotify_artist_id} artist_id=#{artist.id}: #{e.message}"
      end
  end
end
