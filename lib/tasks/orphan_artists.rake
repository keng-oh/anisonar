namespace :artists do
  desc "曲に紐づかない孤児アーティストを一覧する（DELETE=true で削除）"
  task cleanup_orphans: :environment do
    orphans = Artist.orphans

    if orphans.empty?
      puts "孤児アーティストはありません。"
      next
    end

    puts "孤児アーティスト #{orphans.count}件:"
    orphans.find_each { |a| puts "  ##{a.id} #{a.name} (作成: #{a.created_at.strftime('%Y-%m-%d %H:%M')})" }

    unless ENV["DELETE"] == "true"
      puts "\n削除する場合は DELETE=true を付けて再実行してください。"
      next
    end

    deleted = 0
    orphans.find_each do |artist|
      artist.destroy!
      deleted += 1
    rescue => e
      puts "  ##{artist.id} の削除に失敗: #{e.message}"
    end
    puts "\n#{deleted}件を削除しました。"
  end
end
