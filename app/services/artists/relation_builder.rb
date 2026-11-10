module Artists
  # 関係の相手のアーティストを解決する。
  #
  # - artist_id があればそのアーティスト
  # - 名前なら、同じ正規化名の既存のアーティストを使う（種別が合うものを優先）。無ければ作る
  class RelationBuilder
    def self.resolve(...) = new(...).resolve

    def initialize(user:, artist_id: nil, name: nil, artist_type: nil, anime_id: nil)
      @artist_id   = artist_id
      @name        = name.to_s.strip
      @artist_type = artist_type.presence || "person"
      @anime_id    = anime_id
      @user        = user
    end

    def resolve
      return Artist.find(@artist_id) if @artist_id.present?

      existing = Artist.where(normalized_name: NameNormalizer.call(@name)).order(:id).to_a
      existing.find { |a| a.artist_type == @artist_type } || existing.first || create
    end

    private

      def create
        Artist.create!(
          name:            @name,
          artist_type:     @artist_type,
          anime_id:        (@anime_id.presence if @artist_type == "character"),
          created_by_user: @user,
          updated_by_user: @user
        )
      end
  end
end
