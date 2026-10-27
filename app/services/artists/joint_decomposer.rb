module Artists
  # 連名のアーティストに構成メンバーを設定し、連名（joint）として確定する。
  #
  # - メンバーは既存のアーティストを指定するか、名前・種別から新しく作る（同じ名前の既存があればそれを使う）
  # - メンバーとは credited_in（メンバー → 連名）で結び、指定から外れたメンバーの関係は消す
  # - 連名には Spotify の ID を付けないため消す。消した ID は呼び出し側でメンバーに移せるよう返す
  # - 確定したら、連名の曲を Spotify に照合し直す（メンバーの ID で照合できるようになるため）
  class JointDecomposer
    Result = Data.define(:errors, :previous_spotify_artist_id) do
      def success? = errors.empty?
    end
    MIN_MEMBERS = 2

    def self.call(...) = new(...).call

    # @param members [Array<Hash>] { artist_id: } か { name:, artist_type:, anime_id: }
    def initialize(artist:, members:, user:)
      @artist  = artist
      @members = members.map { |m| m.to_h.symbolize_keys }.reject { |m| m[:artist_id].blank? && m[:name].blank? }
      @user    = user
    end

    def call
      return failure("メンバーを#{MIN_MEMBERS}人以上指定してください") if @members.size < MIN_MEMBERS

      previous = @artist.spotify_artist_id
      too_few = false
      ApplicationRecord.transaction do
        # 新しく作ったメンバーが連名自身や他のメンバーと同じ名前だった場合に備え、解決後の件数で確かめる
        member_ids = @members.map { |m| resolve(m).id }.uniq - [ @artist.id ]
        if member_ids.size < MIN_MEMBERS
          too_few = true
          raise ActiveRecord::Rollback
        end

        @artist.credit_member_relations.where.not(from_artist_id: member_ids).destroy_all
        member_ids.each { |id| @artist.credit_member_relations.find_or_create_by!(from_artist_id: id) }
        @artist.update!(artist_type: :joint, spotify_artist_id: nil, updated_by_user: @user)
      end
      return failure("メンバーを#{MIN_MEMBERS}人以上指定してください") if too_few

      @artist.songs.spotify_unlinked.find_each { |song| SpotifyTrackResolveJob.perform_later(song.id) }
      Result.new(errors: [], previous_spotify_artist_id: previous)
    rescue ActiveRecord::RecordInvalid => e
      failure(*e.record.errors.full_messages.map { |msg| "#{e.record.try(:name)}: #{msg}" })
    rescue ActiveRecord::RecordNotFound
      failure("指定したアーティストが見つかりません")
    end

    private

      def resolve(member)
        return Artist.find(member[:artist_id]) if member[:artist_id].present?

        name = member[:name].to_s.strip
        Artist.find_by(normalized_name: NameNormalizer.call(name)) ||
          Artist.create!(
            name:            name,
            artist_type:     member[:artist_type].presence || "person",
            anime_id:        (member[:anime_id].presence if member[:artist_type] == "character"),
            created_by_user: @user,
            updated_by_user: @user
          )
      end

      def failure(*errors)
        Result.new(errors: errors, previous_spotify_artist_id: nil)
      end
  end
end
