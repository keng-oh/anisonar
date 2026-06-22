class AnimesController < ApplicationController
  def index
    base = Anime.with_songs.includes(:anime_series)
    base = base.search(params[:q]) if params[:q].present?
    base = base.by_season(params[:season]) if params[:season].present?

    @latest_animes = base.order(season: :desc, title: :asc).limit(12)

    grouped = base.order(watchers_count: :desc).group_by(&:anime_series)
    @series_groups = grouped.reject { |s, _| s.nil? }
      .sort_by { |_, series_animes| -series_animes.map(&:watchers_count).max }
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
