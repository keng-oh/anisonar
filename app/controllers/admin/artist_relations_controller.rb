module Admin
  # アーティスト同士の関係（声優とキャラクター、メンバーとユニット）を追加・削除する（#112）
  class ArtistRelationsController < BaseController
    before_action :set_artist

    # 編集画面の「関係」の欄（立場）ごとの、関係の種別・向き・相手の種別
    #   self_is: 編集中のアーティストが from / to のどちらか
    SLOTS = {
      "characters"   => { relation_type: :voice_of,  self_is: :from, other_types: %w[character] },
      "voice_actors" => { relation_type: :voice_of,  self_is: :to,   other_types: %w[person] },
      "units"        => { relation_type: :member_of, self_is: :from, other_types: %w[unit] },
      "members"      => { relation_type: :member_of, self_is: :to,   other_types: %w[person character] }
    }.freeze

    # 編集中のアーティストの種別ごとに出せる欄
    SLOTS_BY_ARTIST_TYPE = {
      "person"    => %w[characters units],
      "character" => %w[voice_actors units],
      "unit"      => %w[members]
    }.freeze

    def create
      slot = SLOTS[params[:slot].to_s]
      return redirect_back_to_edit(alert: "この関係は追加できません") unless slot && SLOTS_BY_ARTIST_TYPE.fetch(@artist.artist_type, []).include?(params[:slot])

      relation = nil
      ApplicationRecord.transaction do
        other = resolve_other(slot)
        from, to = slot[:self_is] == :from ? [ @artist, other ] : [ other, @artist ]
        relation = ArtistRelation.new(from_artist: from, to_artist: to, relation_type: slot[:relation_type])
        raise ActiveRecord::Rollback unless relation.save
      end

      if relation&.persisted?
        redirect_back_to_edit(notice: "関係を追加しました")
      else
        redirect_back_to_edit(alert: relation ? relation.errors.full_messages.to_sentence : "関係を追加できませんでした")
      end
    rescue ActiveRecord::RecordInvalid => e
      redirect_back_to_edit(alert: e.record.errors.full_messages.to_sentence)
    rescue ActiveRecord::RecordNotFound
      redirect_back_to_edit(alert: "指定したアーティストが見つかりません")
    end

    def destroy
      relation = ArtistRelation.where(from_artist_id: @artist.id).or(ArtistRelation.where(to_artist_id: @artist.id)).find(params[:id])
      relation.destroy!
      redirect_back_to_edit(notice: "関係を外しました")
    end

    private

      def set_artist
        @artist = Artist.find(params[:artist_id])
      end

      def resolve_other(slot)
        type = params[:artist_type].presence_in(slot[:other_types]) || slot[:other_types].first
        Artists::RelationBuilder.resolve(
          artist_id: params[:other_artist_id], name: params[:name], artist_type: type,
          anime_id: params[:anime_id], user: current_user
        )
      end

      def redirect_back_to_edit(**flash)
        redirect_to edit_admin_artist_path(@artist), **flash
      end
  end
end
