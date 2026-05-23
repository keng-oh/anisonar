module Admin
  class SongsController < BaseController
    def index
      songs = Song.pending_review.includes(:artist, :animes).order(created_at: :asc)
      @songs = songs
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
  end
end
