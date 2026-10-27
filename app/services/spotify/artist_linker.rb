module Spotify
  # spotify_artist_id が未設定の既存アーティストに Spotify のアーティストを紐づける。
  #
  # 1. そのアーティストの曲が既に Spotify のトラックに紐づいていれば、トラックのアーティストを使う
  #    （手動で紐づけた曲も含む。名前で探すより確実なため最優先）
  # 2. 無ければ ArtistMatcher でアーティスト名を検索し、曲で裏付けが取れた候補を使う
  #
  # 紐づけたら、まだ Spotify に紐づいていない曲を再照合する（ID が決まると TrackResolver が
  # ID で候補を絞れるようになり、名義の表記違いで落ちていた曲が解決するため）。
  class ArtistLinker
    Result = Data.define(:status, :spotify_artist, :source, :conflict)
    MAX_TRACKS = 3

    def self.call(...) = new(...).call

    def initialize(artist:, dry_run: false, client: Spotify::Client.new)
      @artist  = artist
      @dry_run = dry_run
      @client  = client
    end

    # status: :linked / :conflict（そのIDは別のアーティストが使用中。重複レコードの疑い）/ :not_found
    def call
      # 連名には ID を付けない（メンバーに付ける）
      return Result.new(status: :not_found, spotify_artist: nil, source: nil, conflict: nil) if @artist.joint?

      source = :track
      match = from_linked_tracks
      unless match
        source = :search
        match = Spotify::ArtistMatcher.call(name: @artist.name, titles: @artist.songs.pluck(:title), client: @client)
      end
      return Result.new(status: :not_found, spotify_artist: nil, source: nil, conflict: nil) unless match

      conflict = Artist.where.not(id: @artist.id).find_by(spotify_artist_id: match["id"])
      return Result.new(status: :conflict, spotify_artist: match, source: source, conflict: conflict) if conflict

      link!(match) unless @dry_run
      Result.new(status: :linked, spotify_artist: match, source: source, conflict: nil)
    end

    private

      # 連名の曲のトラックにはメンバー全員が並び、そのうち1人が検索候補にも出るため、連名には使わない
      def from_linked_tracks
        return nil if Spotify::ArtistMatcher.joint_name?(@artist.name)

        track_ids = PlatformLink.where(platform: :spotify, song_id: @artist.songs.select(:id))
                                .limit(MAX_TRACKS).pluck(:platform_track_id)
        return nil if track_ids.empty?

        candidates = @client.search_artist(@artist.name, limit: Spotify::ArtistMatcher::CANDIDATE_LIMIT)
        track_ids.each do |id|
          match = pick_artist(@client.get_track(id)["artists"] || [], candidates)
          return match if match
        end
        nil
      end

      # トラックのアーティストのうち、名前が一致するか、アーティスト名の検索候補に入っているものを選ぶ。
      # 1人だけでも無条件には採用しない。DBの「小野大輔」の曲が「エルヴィン・スミス(CV:小野大輔)」名義の
      # トラックに紐づいていることがあり、声優本人にキャラ名義のIDを入れてしまうため。
      def pick_artist(track_artists, candidates)
        track_artists.each do |a|
          candidate = candidates.find { |c| c["id"] == a["id"] }
          return candidate if candidate
          return a if NameNormalizer.call(a["name"]) == @artist.normalized_name
        end
        nil
      end

      def link!(match)
        attrs = { spotify_artist_id: match["id"] }
        image_url = match.dig("images", 0, "url")
        attrs[:image_url] = image_url if @artist.image_url.blank? && image_url.present?
        @artist.update!(attrs)
        unlinked = @artist.songs.where.missing(:platform_links)
        unlinked.find_each { |song| SpotifyTrackResolveJob.perform_later(song.id) }
      end
  end
end
