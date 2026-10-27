class AnimesController < ApplicationController
  include Pagy::Method

  def index
    results = Anime.with_songs.includes(:anime_series)
    results = results.search(params[:q]) if params[:q].present?
    results = results.by_season(params[:season]) if params[:season].present?
    @pagy, @search_results = pagy(:offset, results.order(watchers_count: :desc), limit: 48)
    @seasons = Anime.distinct.pluck(:season).compact.sort.reverse
  end

  def show
    @anime = Anime.find(params[:id])
    @anime_songs = @anime.anime_songs
      .includes(song: [ :artist, :platform_links ])
      .order(:song_type)
  end
end
