module Admin
  # 連名のアーティストの構成メンバーを設定する（#26）
  class ArtistMembersController < BaseController
    before_action :set_artist

    def edit
      @rows = initial_rows
      @animes = Anime.where(id: AnimeSong.where(song_id: @artist.songs.select(:id)).select(:anime_id)).order(:title)
    end

    def update
      result = Artists::JointDecomposer.call(artist: @artist, members: members_params, user: current_user)

      if result.success?
        notice = "「#{@artist.name}」を連名として確定しました"
        if result.previous_spotify_artist_id.present?
          notice += "。付いていた Spotify ID（#{result.previous_spotify_artist_id}）は外しました。メンバーの誰かの ID であれば、そのメンバーに紐づけてください"
        end
        redirect_to edit_admin_artist_path(@artist), notice: notice
      else
        redirect_to edit_admin_artist_members_path(@artist), alert: result.errors.to_sentence
      end
    end

    private

      def set_artist
        @artist = Artist.find(params[:artist_id])
      end

      def members_params
        params.permit(members: [ :artist_id, :name, :artist_type, :anime_id ]).fetch(:members, []).map(&:to_h)
      end

      # 設定済みのメンバーがいればそれを、いなければ名前から作った候補を初期値にする
      def initial_rows
        if @artist.credit_members.any?
          @artist.credit_members.map { |m| row(m.name, m) }
        else
          Artists::JointMemberCandidates.call(artist: @artist).map do |c|
            c.artist ? row(c.name, c.artist) : { mode: "new", artist_id: nil, label: "", name: c.name, artist_type: c.artist_type, anime_id: c.anime_id }
          end
        end
      end

      def row(name, artist)
        { mode: "existing", artist_id: artist.id, label: "#{artist.name}（#{helpers.artist_type_label(artist.artist_type)}）",
          name: name, artist_type: artist.artist_type, anime_id: artist.anime_id }
      end
  end
end
