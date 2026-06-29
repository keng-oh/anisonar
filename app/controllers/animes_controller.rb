class AnimesController < ApplicationController
  def index
    if params[:q].present? || params[:season].present?
      results = Anime.with_songs.includes(:anime_series)
      results = results.search(params[:q]) if params[:q].present?
      results = results.by_season(params[:season]) if params[:season].present?
      @search_results = results.order(watchers_count: :desc)
      @seasons = Anime.distinct.pluck(:season).compact.sort.reverse
      return
    end

    @song_count = Song.count
    @anime_count = Anime.count
    @quick_tags = Anime.with_songs.order(watchers_count: :desc).limit(6).pluck(:title)

    @current_season = Anime.airing.group(:season).count.max_by { |_, count| count }&.first
    airing = Anime.airing.with_songs.includes(:anime_series)
    airing = airing.by_season(@current_season) if @current_season.present?
    @airing_animes = airing.order(watchers_count: :desc).limit(8)
    @airing_animes = Anime.airing.with_songs.includes(:anime_series).order(watchers_count: :desc).limit(8) if @airing_animes.empty?

    @recent_songs = Song
      .includes(:artist, anime_songs: :anime)
      .order(created_at: :desc)
      .limit(10)

    covers = Anime.where.not(cover_image_url: [ nil, "" ]).order(watchers_count: :desc).limit(16).to_a
    @hero_row1 = covers + covers
    @hero_row2 = covers.rotate(covers.size / 2) + covers.rotate(covers.size / 2)
    @hero_row3 = covers.reverse + covers.reverse
  end

  def show
    @anime = Anime.find(params[:id])
    @anime_songs = @anime.anime_songs
      .includes(song: [ :artist, :platform_links ])
      .order(:song_type)
  end
end
