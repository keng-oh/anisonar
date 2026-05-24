class AnimesController < ApplicationController
  def index
    animes = Anime.all
    animes = animes.search(params[:q]) if params[:q].present?
    animes = animes.by_season(params[:season]) if params[:season].present?
    animes = animes.includes(:anime_series).order(season: :desc, title: :asc)

    grouped = animes.group_by(&:anime_series)
    @series_groups = grouped.reject { |s, _| s.nil? }.sort_by { |s, _| s.name }
    @standalone_animes = grouped[nil] || []

    @seasons = Anime.distinct.pluck(:season).compact.sort.reverse
  end

  def show
    @anime = Anime.find(params[:id])
    @anime_songs = @anime.anime_songs
      .joins(:song).merge(Song.approved)
      .includes(song: [ :artist, :platform_links ])
      .order(:song_type)
  end
end
