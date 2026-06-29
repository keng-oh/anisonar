module Deduplication
  # Deduplication::ArtistMerger でアーティストを統合した後、同一アーティスト配下で
  # 正規化タイトルが一致する楽曲を1件に統合する（表記揺れで分裂していた楽曲を解消する）。
  class SongMerger
    def call
      groups = Song.all.group_by { |s| [ s.artist_id, NameNormalizer.call(s.title) ] }
      groups.each_value { |songs| merge_group(songs) if songs.size > 1 }
    end

    private

      def merge_group(songs)
        canonical, *duplicates = songs.sort_by(&:created_at)

        duplicates.each do |dup|
          ApplicationRecord.transaction { merge_song(dup, into: canonical) }
        end
      end

      def merge_song(dup, into:)
        reassign(AnimeSong.where(song_id: dup.id), song_id: into.id)
        reassign(SeriesSong.where(song_id: dup.id), song_id: into.id)
        reassign(PlatformLink.where(song_id: dup.id), song_id: into.id)
        reassign_reviews(dup, into)
        dup.destroy!
      end

      def reassign(records, attrs)
        records.find_each do |record|
          record.update!(attrs)
        rescue ActiveRecord::RecordInvalid
          record.destroy!
        end
      end

      def reassign_reviews(dup, into)
        Review.where(reviewable_type: "Song", reviewable_id: dup.id).find_each do |review|
          review.update!(reviewable_id: into.id)
        rescue ActiveRecord::RecordInvalid
          review.destroy!
        end
      end
  end
end
