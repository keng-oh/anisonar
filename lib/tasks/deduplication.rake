namespace :deduplication do
  desc "表記揺れ（区切り文字・括弧）で重複登録されたアーティスト・楽曲を統合する"
  task artists_and_songs: :environment do
    puts "Merging duplicate artists..."
    Deduplication::ArtistMerger.new.call

    puts "Merging duplicate songs..."
    Deduplication::SongMerger.new.call

    puts "Done."
  end
end
