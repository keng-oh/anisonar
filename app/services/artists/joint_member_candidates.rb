module Artists
  # 連名のアーティストの名前から、構成メンバーの候補を作る。管理画面で人が確認してから確定する。
  #
  # 区切りで分けた断片を、既存のアーティストと正規化した名前の完全一致で照合する。
  # 隣り合う断片をつないだ表記が既存のアーティストに一致すれば、つないだまま候補にする
  # （「MYTH & ROID feat. TK」を「MYTH」「ROID」に分けないため）。
  class JointMemberCandidates
    Candidate = Data.define(:name, :artist, :artist_type, :anime_id)
    # 「アクア（雨宮天）」のような「キャラクター名（声優名）」の形
    CHARACTER_NAME = /[(（][^()（）]+[)）]\z/

    def self.call(...) = new(...).call

    def initialize(artist:)
      @artist = artist
    end

    # @return [Array<Candidate>] 分けられなければ空配列
    def call
      spans = JointNameSplitter.spans(@artist.name)
      candidates = []
      i = 0
      while i < spans.size
        j, existing = longest_existing_run(spans, i)
        candidates << build(text_between(spans[i], spans[j]), existing)
        i = j + 1
      end
      candidates
    end

    private

      def longest_existing_run(spans, i)
        last = spans.size - 1
        last.downto(i + 1) do |j|
          next if i.zero? && j == last # 名前全体は連名そのもの

          existing = find_existing(text_between(spans[i], spans[j]))
          return [ j, existing ] if existing
        end
        [ i, find_existing(spans[i].text) ]
      end

      def text_between(first, last)
        @artist.name[first.from...last.to]
      end

      def find_existing(name)
        Artist.where.not(id: @artist.id).find_by(normalized_name: NameNormalizer.call(name))
      end

      def build(name, existing)
        return Candidate.new(name: existing.name, artist: existing, artist_type: existing.artist_type, anime_id: existing.anime_id) if existing

        character = CHARACTER_NAME.match?(name)
        Candidate.new(name: name, artist: nil, artist_type: character ? "character" : "person", anime_id: (default_anime_id if character))
      end

      # キャラクターは所属アニメが必須なので、連名の曲が紐づくアニメを初期値にする
      def default_anime_id
        @default_anime_id ||= AnimeSong.where(song_id: @artist.songs.select(:id)).pick(:anime_id)
      end
  end
end
