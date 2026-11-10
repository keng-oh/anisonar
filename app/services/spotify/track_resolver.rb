module Spotify
  # 楽曲名 + アーティスト名で Spotify を検索し、最も一致するトラックを
  # PlatformLink (platform: :spotify) として保存する。
  class TrackResolver
    def self.call(...) = new(...).call

    def initialize(song:, client: Spotify::Client.new)
      @song   = song
      @client = client
    end

    def call
      track, stage = best_match
      return nil unless track

      # 作品名義・声優名義で見つかったときは、キャラクターのアーティストに ID を付けない
      backfill_artist_spotify_id(track) if stage == :own

      album_data = track["album"] || {}

      if album_data["id"].present? && album_data["name"].present?
        album = Album.find_or_create_by!(spotify_album_id: album_data["id"]) do |a|
          a.name         = album_data["name"]
          a.image_url    = album_data.dig("images", 0, "url")
          a.release_date = album_data["release_date"]
        end
        @song.update_columns(album_id: album.id)
      end

      link = @song.platform_links.find_or_initialize_by(platform: :spotify)
      link.platform_track_id = track["id"]
      link.save!
      link
    end

    private

      # 本人名義 → 声優名義 → 作品名義の順に試し、最初に見つかったトラックと段を返す。
      # 検索はアーティスト名で絞らず（Spotify 側の表記違いで0件になるため）、曲名と名義で確かめる。
      # 曲名が一致しないトラックは、どの段でも採用しない。確信が持てない場合は nil を返す
      def best_match
        if @song.artist.joint?
          track = joint_match
          return track && [ track, :joint ]
        end

        track = own_match
        return [ track, :own ] if track

        return nil if Spotify::ArtistMatcher.joint_name?(@song.artist.name)

        track = voice_match
        return [ track, :voice ] if track

        track = work_match
        track && [ track, :work ]
      end

      # 連名の曲は、Spotify の ID を持つメンバーの名前で検索し、そのメンバー全員がトラックに並び、
      # 曲名も一致するものだけを採用する（一部のメンバーで良しとすると、メンバー単独版を選んでしまうため）。
      # Spotify に連名のアーティストは存在しないので、連名の名前では検索しない
      def joint_match
        members = @song.artist.credit_members.where.not(spotify_artist_id: nil).to_a
        return nil if members.empty?

        # artist:"…" で絞ると、Spotify 側の表記（「アクア (CV: 雨宮 天)」）と違う名前では0件になるため、
        # 条件を付けずに検索し、メンバーの ID で確かめる
        query = "#{@song.title} #{members.first.name}"
        @client.search_track(query, limit: Spotify::ArtistMatcher::TRACK_LIMIT).find do |t|
          track_artist_ids = t["artists"].map { |a| a["id"] }
          members.all? { |m| track_artist_ids.include?(m.spotify_artist_id) } &&
            Spotify::ArtistMatcher.same_title?(t["name"], @song.title)
        end
      end

      # 本人名義。部分一致では採らない（名前全体か「かっこの外」と丸ごと一致するときだけ）
      def own_match
        artist = @song.artist
        search(artist.name).find do |t|
          if artist.spotify_artist_id.present?
            t["artists"].any? { |a| a["id"] == artist.spotify_artist_id }
          else
            own_artist?(t)
          end
        end
      end

      # 「キャラ（声優）」名義の曲が、声優本人の名義で配信されているもの
      def voice_match
        voice_candidates.each do |voice|
          key = NameNormalizer.credit_key(voice[:name])
          track = search(voice[:name]).find do |t|
            t["artists"].any? do |a|
              (voice[:id].present? && a["id"] == voice[:id]) || NameNormalizer.credit_key(a["name"]) == key
            end
          end
          return track if track
        end
        nil
      end

      # 作品名義（物語シリーズなど）で配信されているもの。カバー・カラオケは作品名と一致しないので落ちる
      def work_match
        work_titles.each do |title|
          key = NameNormalizer.title_key(title)
          track = search(title).find { |t| t["artists"].any? { |a| NameNormalizer.title_key(a["name"]) == key } }
          return track if track
        end
        nil
      end

      # 曲名 + 名前で絞らずに検索し、曲名が一致するものだけ返す
      def search(name)
        @client.search_track("#{@song.title} #{name}", limit: Spotify::ArtistMatcher::TRACK_LIMIT)
               .select { |t| Spotify::ArtistMatcher.same_title?(t["name"], @song.title) }
      end

      # 本人名義とみなす名前のキー: 名前全体と、「キャラ名（声優名）」の形ならかっこの外
      def own_keys
        name = @song.artist.name
        keys = [ NameNormalizer.credit_key(name) ]
        if Artists::JointMemberCandidates::CHARACTER_NAME.match?(name)
          outside = name.sub(Artists::JointMemberCandidates::CHARACTER_NAME, "")
          keys << NameNormalizer.credit_key(outside) if outside.present?
        end
        keys.compact_blank
      end

      def own_artist?(track)
        track["artists"].any? { |a| own_keys.include?(NameNormalizer.credit_key(a["name"])) }
      end

      # voice_of で設定された声優。無ければ名前のかっこの中（複数人は除く）
      def voice_candidates
        related = ArtistRelation.voice_of.where(to_artist: @song.artist).includes(:from_artist).map(&:from_artist)
        return related.map { |v| { name: v.name, id: v.spotify_artist_id } } if related.any?

        name = @song.artist.name
        return [] unless Artists::JointMemberCandidates::CHARACTER_NAME.match?(name)

        inner = name[/[(（]([^()（）]+)[)）]\z/, 1].to_s.strip
        return [] if inner.blank? || JointNameSplitter.call(inner).any?

        [ { name: inner, id: nil } ]
      end

      # 曲のシリーズ名 → 曲のアニメのタイトル → そのシリーズ名 → キャラクターのアニメのタイトル → そのシリーズ名
      # （title_key で重複と空を除き最大 3 件）
      def work_titles
        names = @song.anime_series.map(&:name)
        song_animes = @song.animes.includes(:anime_series).to_a
        names += song_animes.map(&:title) + song_animes.map { |a| a.anime_series&.name }
        if (anime = @song.artist.anime)
          names += [ anime.title, anime.anime_series&.name ]
        end
        names.compact_blank.uniq { |n| NameNormalizer.title_key(n) }
             .reject { |n| NameNormalizer.title_key(n).blank? }
             .first(Spotify::ArtistMatcher::MAX_TITLES)
      end

      # 本人名義で一致したときだけ補完する。連名（joint）には補完しない
      # （update_columns はバリデーション（joint なら ID は空）を通らないので、ここで止める）。
      # 丸ごと一致だけなので、メンバー（かっこの中）の名前では一致しない
      def backfill_artist_spotify_id(track)
        return if @song.artist.spotify_artist_id.present?
        return if @song.artist.joint?

        matched = track["artists"].find { |a| own_keys.include?(NameNormalizer.credit_key(a["name"])) }
        return unless matched

        @song.artist.update_columns(spotify_artist_id: matched["id"])
      rescue => e
        Rails.logger.warn "[Spotify::TrackResolver] failed to backfill spotify_artist_id artist_id=#{@song.artist_id}: #{e.message}"
      end
  end
end
