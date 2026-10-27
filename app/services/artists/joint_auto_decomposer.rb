module Artists
  # 連名の曲の Spotify トラックから、連名を自動でメンバーに分解する（#78）。
  #
  # Spotify に連名のアーティストは存在せず、トラックの artists に参加者が1人ずつ並ぶ。
  # 連名の名前を区切った断片と、トラックのアーティストが1対1で対応するときだけ分解する。
  # 対応が取れなければ（Spotify に曲が無い、表記が大きく違う、人数が違う）何もせず、管理画面での手作業に残す。
  #
  # 隣り合う断片は、まとめて1人に対応させてよい（「MYTH & ROID feat. TK」の「MYTH」「ROID」）。
  # Spotify のトラックでは「MYTH & ROID」が1人として並ぶため、& がユニット名か区切りかがここで決まる。
  class JointAutoDecomposer
    Result = Data.define(:status, :members) do
      def decomposed? = status == :decomposed
    end
    Member = Data.define(:name, :spotify_artist_id, :spotify_name, :artist)
    MAX_SONGS = 3

    def self.call(...) = new(...).call

    def initialize(artist:, dry_run: false, client: Spotify::Client.new)
      @artist  = artist
      @dry_run = dry_run
      @client  = client
    end

    # status: :decomposed（dry_run では分解できる見込み）/ :not_found（対応するトラックが無い）/
    #         :skipped（連名の形でない・分解済み）/ :failed（対応は取れたが保存できなかった）
    def call
      return result(:skipped) if @artist.joint?

      @spans = JointNameSplitter.spans(@artist.name)
      return result(:skipped) if @spans.empty?

      candidate_tracks.each do |track|
        pairs = pair(track["artists"] || [])
        next unless pairs

        members = pairs.map { |text, a| Member.new(name: text, spotify_artist_id: a["id"], spotify_name: a["name"], artist: existing_member(text, a)) }
        return result(:failed, members) unless @dry_run || decompose!(members)

        return result(:decomposed, members)
      end
      result(:not_found)
    end

    private

      def result(status, members = [])
        Result.new(status: status, members: members)
      end

      # 曲が Spotify に紐づいていればそのトラック、無ければ最初の断片と曲名で検索した候補
      def candidate_tracks
        Enumerator.new do |y|
          @artist.songs.includes(:platform_links).limit(MAX_SONGS).each do |song|
            link = song.platform_links.find(&:spotify?)
            if link
              y << @client.get_track(link.platform_track_id)
            else
              # artist:"…" で絞ると、Spotify 側の表記（「アクア (CV: 雨宮 天)」）と違う名前では0件になるため、条件を付けずに検索する
              query = "#{song.title} #{@spans.first.text}"
              @client.search_track(query, limit: Spotify::ArtistMatcher::TRACK_LIMIT)
                     .select { |t| Spotify::ArtistMatcher.same_title?(t["name"], song.title) }
                     .each { |t| y << t }
            end
          end
        end
      end

      # 断片（隣り合うものはまとめてよい）とトラックのアーティストを、並び順どおりに1対1で対応させる。
      # 順どおりに取れず、断片とアーティストが同じ数なら、順不同での対応も試す
      def pair(track_artists)
        return nil if track_artists.size < 2

        in_order(0, 0, track_artists) || (unordered(track_artists) if @spans.size == track_artists.size)
      end

      def in_order(span_i, artist_i, track_artists)
        return [] if span_i == @spans.size && artist_i == track_artists.size
        return nil if span_i == @spans.size || artist_i == track_artists.size

        (span_i...@spans.size).each do |span_j|
          text = @artist.name[@spans[span_i].from...@spans[span_j].to]
          next unless same_credit?(text, track_artists[artist_i])

          rest = in_order(span_j + 1, artist_i + 1, track_artists)
          return [ [ text, track_artists[artist_i] ], *rest ] if rest
        end
        nil
      end

      def unordered(track_artists)
        remaining = track_artists.dup
        pairs = @spans.map do |span|
          found = remaining.find { |a| same_credit?(span.text, a) }
          return nil unless found

          remaining.delete(found)
          [ span.text, found ]
        end
        pairs
      end

      # 「アクア（雨宮天）」と Spotify の「アクア (CV: 雨宮 天)」を同じとみなす（空白・幅・「CV:」を無視）。
      # 名前が違っても、その Spotify ID を持つ既存のアーティストの名前が一致すれば同じとみなす（Eir Aoi など）
      def same_credit?(text, track_artist)
        credit_key(text) == credit_key(track_artist["name"]) ||
          Artist.where(spotify_artist_id: track_artist["id"], normalized_name: NameNormalizer.call(text)).exists?
      end

      def credit_key(name)
        NameNormalizer.call(name).gsub(/cv[.:：]?/, "")
      end

      def existing_member(text, track_artist)
        Artist.where.not(id: @artist.id).find_by(spotify_artist_id: track_artist["id"]) ||
          Artist.where.not(id: @artist.id).find_by(normalized_name: NameNormalizer.call(text))
      end

      # @return [Boolean] 保存できたか
      def decompose!(members)
        ApplicationRecord.transaction do
          artists = members.map { |m| member_artist!(m) }
          result = Artists::JointDecomposer.call(artist: @artist, members: artists.map { |a| { artist_id: a.id } }, user: User.ai_bot)
          unless result.success?
            Rails.logger.warn "[Artists::JointAutoDecomposer] artist_id=#{@artist.id} #{result.errors.to_sentence}"
            raise ActiveRecord::Rollback
          end
          true
        end || false
      rescue ActiveRecord::RecordInvalid => e
        Rails.logger.warn "[Artists::JointAutoDecomposer] artist_id=#{@artist.id} #{e.message}"
        false
      end

      # 既存のメンバーに Spotify ID が無ければトラックの ID を付ける。無ければ連名の表記の名前で作る
      def member_artist!(member)
        artist = member.artist
        if artist
          artist.update!(spotify_artist_id: member.spotify_artist_id) if artist.spotify_artist_id.blank? && !artist.joint?
          return artist
        end

        anime_id = default_anime_id if JointMemberCandidates::CHARACTER_NAME.match?(member.name)
        Artist.create!(
          name:              member.name,
          artist_type:       anime_id ? "character" : "person",
          anime_id:          anime_id,
          spotify_artist_id: member.spotify_artist_id,
          created_by_user:   User.ai_bot,
          updated_by_user:   User.ai_bot
        )
      end

      def default_anime_id
        @default_anime_id ||= AnimeSong.where(song_id: @artist.songs.select(:id)).pick(:anime_id)
      end
  end
end
