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
      @song.created_by_user = current_user
      @song.updated_by_user = current_user

      ApplicationRecord.transaction do
        artist = resolve_artist_in_transaction
        break unless artist

        @song.artist = artist
        unless @song.save
          raise ActiveRecord::Rollback
        end

        sync_anime_songs(@song, params[:song][:anime_entries])
        sync_series_songs(@song, params[:song][:series_entries])
      end

      if @song.persisted?
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

      ApplicationRecord.transaction do
        artist = resolve_artist_in_transaction
        break unless artist

        @song.artist = artist
        @song.updated_by_user = current_user
        unless @song.update(song_params)
          raise ActiveRecord::Rollback
        end

        sync_anime_songs(@song, params[:song][:anime_entries])
        sync_series_songs(@song, params[:song][:series_entries])
      end

      if @song.errors.none?
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
        params.expect(song: [ :title, :status, :notes ])
      end

      def resolve_artist_in_transaction
        if params.dig(:song, :artist_id) == "new"
          artist = Artist.new(inline_artist_params)
          unless artist.save
            artist.errors.each { |e| @song.errors.add(:base, "アーティスト #{e.full_message}") }
            raise ActiveRecord::Rollback
          end
          artist
        else
          Artist.find_by(id: params.dig(:song, :artist_id))
        end
      end

      def inline_artist_params
        params.expect(song: { new_artist: [ :name, :name_kana, :artist_type, :image_url, :anime_id ] })[:new_artist]
      end

      def sync_anime_songs(song, entries)
        song.anime_songs.destroy_all
        Array(entries).each do |entry|
          next if entry[:anime_id].blank?
          song.anime_songs.create!(
            anime_id: entry[:anime_id],
            song_type: entry[:song_type].presence || "op"
          )
        end
      end

      def sync_series_songs(song, entries)
        song.series_songs.destroy_all
        Array(entries).each do |entry|
          next if entry[:anime_series_id].blank?
          song.series_songs.create!(
            anime_series_id: entry[:anime_series_id],
            song_type: entry[:song_type].presence || "op"
          )
        end
      end
  end
end
