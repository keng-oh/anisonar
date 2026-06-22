module Admin
  class SongsController < BaseController
    def index
      @songs = Song.pending_review.includes(:artist, :animes).order(created_at: :asc)
    end

    def new
      @song = Song.new
    end

    def create
      @song = Song.new(song_params)
      @song.created_by_user = current_user

      Songs::SaveService.call(**service_params)

      if @song.persisted?
        redirect_to admin_songs_path, notice: "「#{@song.title}」を登録しました"
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
        redirect_to admin_songs_path, notice: "「#{@song.title}」を更新しました"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def approve
      song = Song.find(params[:id])
      song.approve!
      SpotifyTrackResolveJob.perform_later(song.id) if song.spotify_link.nil?
      redirect_to admin_songs_path, notice: "「#{song.title}」を承認しました"
    end

    def reject
      song = Song.find(params[:id])
      song.reject!
      redirect_to admin_songs_path, notice: "「#{song.title}」を否認しました"
    end

    def bulk_spotify_resolve
      limit = (params[:limit].presence || 20).to_i.clamp(1, 100)
      songs = Song.approved
                  .left_joins(:platform_links)
                  .where(platform_links: { id: nil })
                  .limit(limit)
      songs.each { |song| SpotifyTrackResolveJob.perform_later(song.id) }
      redirect_to admin_songs_path, notice: "#{songs.size} 件のSpotify検索を開始しました"
    end

    private

      def song_params
        params.expect(song: [ :title, :status, :notes ])
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
  end
end
