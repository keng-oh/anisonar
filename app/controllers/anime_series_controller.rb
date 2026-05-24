class AnimeSeriesController < ApplicationController
  def show
    @series = AnimeSeries.find(params[:id])
    @animes = @series.animes.order(series_order: :asc, season: :asc, title: :asc)

    @anime_songs_by_anime = AnimeSong
      .joins(:song).merge(Song.approved)
      .where(anime_id: @animes.map(&:id))
      .includes(:anime, song: [ :artist, :platform_links ])
      .order(:song_type)
      .group_by(&:anime_id)

    @series_songs = @series.series_songs
      .joins(:song).merge(Song.approved)
      .includes(song: [ :artist, :platform_links ])
      .order(:song_type)
  end
end
