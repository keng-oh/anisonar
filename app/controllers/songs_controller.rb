class SongsController < ApplicationController
  def show
    @song = Song.includes(:artist, :animes, :platform_links).find(params[:id])
    @spotify_link = @song.spotify_link
  end
end
