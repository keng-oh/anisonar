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
      @song.registered_by = "admin"
      if @song.save
        sync_anime_songs(@song, params[:song][:anime_ids])
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
      if @song.update(song_params)
        sync_anime_songs(@song, params[:song][:anime_ids])
        redirect_to admin_songs_path, notice: "「#{@song.title}」を更新しました"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def approve
      song = Song.find(params[:id])
      song.approve!
      redirect_to admin_songs_path, notice: "「#{song.title}」を承認しました"
    end

    def reject
      song = Song.find(params[:id])
      song.reject!
      redirect_to admin_songs_path, notice: "「#{song.title}」を否認しました"
    end

    private

      def song_params
        params.expect(song: [ :title, :song_type, :status, :artist_id, :notes ])
      end

      def sync_anime_songs(song, anime_ids)
        song.anime_songs.destroy_all
        Array(anime_ids).reject(&:blank?).each do |anime_id|
          song.anime_songs.create!(anime_id:)
        end
      end
  end
end
