class AnimesController < ApplicationController
  def index
    animes = Anime.all
    animes = animes.search(params[:q]) if params[:q].present?
    animes = animes.by_season(params[:season]) if params[:season].present?
    animes = animes.order(season: :desc, title: :asc)
    @animes = animes
    @seasons = Anime.distinct.pluck(:season).compact.sort.reverse
  end

  def show
    @anime = Anime.includes(songs: [ :artist, :platform_links ]).find(params[:id])
    @songs = @anime.songs.approved.includes(:artist, :platform_links)
  end
end
