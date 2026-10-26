module Spotify
  # アーティスト名で Spotify を検索し、同一人物・同一ユニットと判断できるアーティストを返す。
  # 候補は管理画面の「Spotifyで検索」と同じ検索結果（search_artist）から選ぶ。
  #
  # Spotify 側がローマ字・英語名義（藍井エイル → Eir Aoi）や「キャラ名 (CV: 声優名)」表記でも、
  # 検索自体は別名を引けるため候補には出てくるが、名前の完全一致では採用できない。
  # そこで名前が一致しない候補は、そのアーティストの曲が Spotify 上でその候補の曲として
  # 存在するかで確かめる（同名・類似名の別人への誤結合を防ぐため、名前だけでは採用しない）。
  #
  # 名前が一致する候補も、曲名が分かっていれば曲で確かめる。正規化で大文字小文字をそろえるため、
  # 「LiSA」で検索すると BLACKPINK の「LISA」も名前一致になり、検索順位では後者が上に来ることがある。
  class ArtistMatcher
    CANDIDATE_LIMIT = 5
    # 連名（「YOSHIKI feat. HYDE」「アクア（雨宮天）、めぐみん（高橋李依）」）は、メンバー1人の
    # アーティストに誤結合しやすいため、名前が一致する候補しか採用しない。分解は #26 で扱う
    JOINT_NAME = /\b(feat\.?|ft\.|featuring)\s|[、×]/i
    TRACK_LIMIT = 10 # Search API の limit の上限は 10（2026年2月の仕様変更）
    MAX_TITLES = 3

    def self.call(...) = new(...).call

    def self.joint_name?(name) = JOINT_NAME.match?(name.to_s)

    # @param titles [Array<String>] そのアーティストの曲名（候補の検証に使う）
    def initialize(name:, titles: [], client: Spotify::Client.new)
      @name   = name
      @titles = Array(titles).compact_blank.uniq.first(MAX_TITLES)
      @client = client
    end

    # @return [Hash, nil] Spotify のアーティスト情報（"id", "name" ...）
    def call
      return nil if @name.blank?

      candidates = @client.search_artist(@name, limit: CANDIDATE_LIMIT)
      name_matches = candidates.select { |a| normalize(a["name"]) == normalize(@name) }
      return unique(name_matches) if @titles.empty?

      others = self.class.joint_name?(@name) ? [] : candidates - name_matches
      (name_matches + others).find { |a| has_track?(a) } || unique(name_matches)
    end

    private

      # 同じ名前の候補が複数あって曲で確かめられないときは、どれとも決めない
      def unique(candidates)
        candidates.first if candidates.size == 1
      end

      def has_track?(candidate)
        @titles.any? do |title|
          tracks = @client.search_track(%(track:"#{title}" artist:"#{candidate['name']}"), limit: TRACK_LIMIT)
          tracks.any? do |t|
            t["artists"].any? { |a| a["id"] == candidate["id"] } && same_title?(t["name"], title)
          end
        end
      end

      # Spotify 側は「曲名 - TV size」「曲名 (Anime Ver.)」のように装飾が付くことがあるため、包含で比べる
      def same_title?(spotify_title, title)
        a = normalize(spotify_title)
        b = normalize(title)
        a.present? && b.present? && (a.include?(b) || b.include?(a))
      end

      def normalize(str)
        NameNormalizer.call(str)
      end
  end
end
