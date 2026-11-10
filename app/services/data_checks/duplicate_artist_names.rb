module DataChecks
  class DuplicateArtistNames
    KEY = "duplicate_artist_names"
    LABEL = "アーティスト名の重複"
    DESCRIPTION = "正規化した名前が同じアーティストが複数ある（キャラクターは同じアニメの中だけで比べる）"

    def self.call = new.call

    def call
      pairs = Artist.group(:normalized_name, :anime_id).having("COUNT(*) > 1").pluck(:normalized_name, :anime_id)
      return [] if pairs.empty?

      artists = Artist.where(normalized_name: pairs.map(&:first).uniq).order(:id)
                      .select { |artist| pairs.include?([ artist.normalized_name, artist.anime_id ]) }
      siblings = artists.group_by { |artist| [ artist.normalized_name, artist.anime_id ] }
      artists.map do |artist|
        others = siblings[[ artist.normalized_name, artist.anime_id ]].reject { |other| other.id == artist.id }
        Finding.new(record: artist, label: artist.name, detail: "同じ名前のアーティストがほかに #{others.size} 件（ID: #{others.map(&:id).join(', ')}）")
      end
    end
  end
end
