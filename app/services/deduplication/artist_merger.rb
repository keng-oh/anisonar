module Deduplication
  # 表記揺れ（区切り文字・括弧）で重複登録されたアーティストを正規化キーでグルーピングし、1件に統合する。
  # 統合先（canonical）は spotify_artist_id を持つものを優先、なければ作成日時が古いものを優先する。
  class ArtistMerger
    def call
      groups = Artist.all.group_by { |a| NameNormalizer.call(a.name) }
      groups.each_value { |artists| merge_group(artists) if artists.size > 1 }
    end

    private

      def merge_group(artists)
        canonical, *duplicates = artists.sort_by { |a| [ a.spotify_artist_id.present? ? 0 : 1, a.created_at ] }

        duplicates.each do |dup|
          ApplicationRecord.transaction { merge_artist(dup, into: canonical) }
        end
      end

      def merge_artist(dup, into:)
        Song.where(artist_id: dup.id).update_all(artist_id: into.id)
        reassign_artist_relations(dup, into)
        reassign_reviews(dup, into)
        dup.destroy!
      end

      def reassign_artist_relations(dup, into)
        ArtistRelation.where(from_artist_id: dup.id).find_each { |rel| reassign_relation(rel, from_artist_id: into.id) }
        ArtistRelation.where(to_artist_id: dup.id).find_each { |rel| reassign_relation(rel, to_artist_id: into.id) }
      end

      def reassign_relation(rel, attrs)
        rel.assign_attributes(attrs)
        return rel.destroy! if rel.from_artist_id == rel.to_artist_id

        rel.save!
      rescue ActiveRecord::RecordInvalid
        rel.destroy!
      end

      def reassign_reviews(dup, into)
        Review.where(reviewable_type: "Artist", reviewable_id: dup.id).find_each do |review|
          review.update!(reviewable_id: into.id)
        rescue ActiveRecord::RecordInvalid
          review.destroy!
        end
      end
  end
end
