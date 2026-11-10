module DataChecks
  # 点検項目の一覧。表示順もこの順。項目を足すときは、点検クラスを作ってここに1行足す
  module Registry
    CHECKS = [
      DuplicateSongTitles,
      DuplicateArtistNames,
      UnsplitJointArtists,
      SpotifyNotFoundHeavyAnimes,
      CrawlFailures,
      NoisySongTitles
    ].freeze

    def self.find(key)
      CHECKS.find { |check| check::KEY == key }
    end
  end
end
