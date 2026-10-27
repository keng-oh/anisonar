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
      track = best_match
      return nil unless track

      backfill_artist_spotify_id(track)

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

      # 検索結果の artists 配列を、spotify_artist_id（無ければ正規化名）で検証してから採用する。
      # 曲名は表記揺れ・カバー・ライブ版などで誤マッチしやすいため、確信が持てない場合は nil を返す。
      def best_match
        return joint_match if @song.artist.joint?

        query = %(track:"#{@song.title}" artist:"#{@song.artist.name}")
        candidates = @client.search_track(query, limit: 5)

        if @song.artist.spotify_artist_id.present?
          candidates.find { |t| t["artists"].any? { |a| a["id"] == @song.artist.spotify_artist_id } }
        else
          normalized_artist = normalize(@song.artist.name)
          # まず完全一致、なければ部分一致（DBのアーティスト名にSpotifyのアーティスト名が含まれるか）
          candidates.find { |t| t["artists"].any? { |a| normalize(a["name"]) == normalized_artist } } ||
            candidates.find { |t| t["artists"].any? { |a| normalized_artist.include?(normalize(a["name"])) } }
        end
      end

      # 連名の曲は、Spotify の ID を持つメンバーの名前で検索し、そのメンバー全員がトラックに並び、
      # 曲名も一致するものだけを採用する（一部のメンバーで良しとすると、メンバー単独版を選んでしまうため）。
      # Spotify に連名のアーティストは存在しないので、連名の名前では検索しない
      def joint_match
        members = @song.artist.credit_members.where.not(spotify_artist_id: nil).to_a
        return nil if members.empty?

        query = %(track:"#{@song.title}" artist:"#{members.first.name}")
        @client.search_track(query, limit: Spotify::ArtistMatcher::TRACK_LIMIT).find do |t|
          track_artist_ids = t["artists"].map { |a| a["id"] }
          members.all? { |m| track_artist_ids.include?(m.spotify_artist_id) } &&
            Spotify::ArtistMatcher.same_title?(t["name"], @song.title)
        end
      end

      # 連名のアーティストには補完しない。部分一致でメンバー1人の ID が入ってしまうため。
      # update_columns はバリデーション（joint なら ID は空）を通らないので、ここで止める
      def backfill_artist_spotify_id(track)
        return if @song.artist.spotify_artist_id.present?
        return if @song.artist.joint? || Spotify::ArtistMatcher.joint_name?(@song.artist.name)

        normalized = normalize(@song.artist.name)
        matched = track["artists"].find { |a| normalize(a["name"]) == normalized } ||
                  track["artists"].find { |a| normalized.include?(normalize(a["name"])) }
        return unless matched

        @song.artist.update_columns(spotify_artist_id: matched["id"])
      rescue => e
        Rails.logger.warn "[Spotify::TrackResolver] failed to backfill spotify_artist_id artist_id=#{@song.artist_id}: #{e.message}"
      end

      def normalize(str)
        str.to_s.unicode_normalize(:nfkc).downcase.gsub(/\s+/, "")
      end
  end
end
