class AnimeSeriesController < ApplicationController
  def show
    @series = AnimeSeries.find(params[:id])
    @animes = @series.animes.order(series_order: :asc, season: :asc, title: :asc)

    @anime_songs_by_anime = AnimeSong
      .where(anime_id: @animes.map(&:id))
      .includes(:anime, song: [ :artist, :platform_links ])
      .order(:song_type)
      .group_by(&:anime_id)

    @series_songs = @series.series_songs
      .includes(song: [ :artist, :platform_links ])
      .order(:song_type)
  end
end
