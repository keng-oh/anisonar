namespace :spotify do
  desc "Spotify未連携のアーティストを自動で紐づけ、曲を再照合する（DRY_RUN=true で保存せず一覧のみ）"
  task link_artists: :environment do
    dry_run = ENV["DRY_RUN"] == "true"
    client = Spotify::Client.new
    artists = Artist.where(spotify_artist_id: nil).where(id: Song.select(:artist_id)).order(:id)
    counts = Hash.new(0)

    puts "Spotify未連携のアーティスト #{artists.count}件#{'（DRY_RUN: 保存しません）' if dry_run}"
    artists.find_each do |artist|
      result = Spotify::ArtistLinker.call(artist: artist, dry_run: dry_run, client: client)
      counts[result.status] += 1
      sp = result.spotify_artist
      case result.status
      when :linked
        puts "  紐づけ ##{artist.id} #{artist.name} -> #{sp['name']} (#{sp['id']}, #{result.source})"
      when :conflict
        puts "  重複疑い ##{artist.id} #{artist.name} -> #{sp['name']} は ##{result.conflict.id} #{result.conflict.name} が使用中"
      end
    rescue Spotify::Client::Error => e
      counts[:error] += 1
      puts "  失敗 ##{artist.id} #{artist.name}: #{e.message}"
    end

    puts "\n紐づけ #{counts[:linked]}件 / 重複疑い #{counts[:conflict]}件 / 見つからない #{counts[:not_found]}件 / 失敗 #{counts[:error]}件"
    puts "重複疑いは同一アーティストの別表記レコードの可能性があります（統合は未対応のため手動で確認）。" if counts[:conflict].positive?
  end
end
