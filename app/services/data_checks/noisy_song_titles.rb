module DataChecks
  class NoisySongTitles
    KEY = "noisy_song_titles"
    LABEL = "曲名の混入物"
    DESCRIPTION = "曲名に「TV size」「off vocal」など、曲名ではない表記が混じっている"

    PATTERN = /TV\s*(size|サイズ|ver)|off\s*vocal|instrumental|inst\.|カラオケ|karaoke|short\s*ver/i

    def self.call = new.call

    def call
      Song.order(:id).filter_map do |song|
        match = PATTERN.match(song.title)
        Finding.new(record: song, label: song.title, detail: "含まれる文字列: #{match[0]}") if match
      end
    end
  end
end
