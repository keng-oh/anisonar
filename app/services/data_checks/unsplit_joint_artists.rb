module DataChecks
  class UnsplitJointArtists
    KEY = "unsplit_joint_artists"
    LABEL = "連名の未分解"
    DESCRIPTION = "名前に連名の区切りを含むのに、連名（joint）にもユニットにもなっていないアーティストがある"

    def self.call = new.call

    def call
      Artist.unsplit_joint_candidates.order(:id).map do |artist|
        parts = JointNameSplitter.call(artist.name)
        detail = "種別: #{artist.artist_type}"
        detail += "、分けると: #{parts.join(' / ')}" if parts.any?
        Finding.new(record: artist, label: artist.name, detail:)
      end
    end
  end
end
