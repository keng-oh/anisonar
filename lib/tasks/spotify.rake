namespace :spotify do
  desc "Spotify未連携のアーティストを自動で紐づけ、曲を再照合する（DRY_RUN=true で保存せず一覧のみ）"
  task link_artists: :environment do
    dry_run = ENV["DRY_RUN"] == "true"
    client = Spotify::Client.new
    artists = Artist.where(spotify_artist_id: nil).where.not(artist_type: :joint).where(id: Song.select(:artist_id))
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
      when :not_found
        puts "  見つからない ##{artist.id} #{artist.name}"
      end
    rescue Spotify::Client::Error => e
      counts[:error] += 1
      puts "  失敗 ##{artist.id} #{artist.name}: #{e.message}"
    end

    puts "\n紐づけ #{counts[:linked]}件 / 重複疑い #{counts[:conflict]}件 / 見つからない #{counts[:not_found]}件 / 失敗 #{counts[:error]}件"
    puts "重複疑いは同一アーティストの別表記レコードの可能性があります（統合は未対応のため手動で確認）。" if counts[:conflict].positive?
  end

  decompose_joint_artists = lambda do |dry_run:|
    client = Spotify::Client.new
    artists = Artist.unsplit_joint_candidates.where(id: Song.select(:artist_id))
    counts = Hash.new(0)

    puts "連名（未分解）のアーティスト #{artists.count}件#{'（確認のみ: 保存しません）' if dry_run}"
    artists.find_each do |artist|
      result = Artists::JointAutoDecomposer.call(artist: artist, dry_run: dry_run, client: client)
      counts[result.status] += 1
      members = result.members.map { |m| "#{m.name}#{m.artist ? "（既存 ##{m.artist.id}）" : '（新規）'} = #{m.spotify_name}" }.join(" / ")
      case result.status
      when :decomposed then puts "  分解 ##{artist.id} #{artist.name} -> #{members}"
      when :failed then puts "  保存失敗 ##{artist.id} #{artist.name} -> #{members}（ログを確認）"
      when :not_found then puts "  対応するトラックなし ##{artist.id} #{artist.name}"
      end
    rescue Spotify::Client::Error => e
      counts[:error] += 1
      puts "  失敗 ##{artist.id} #{artist.name}: #{e.message}"
    end

    puts "\n分解 #{counts[:decomposed]}件 / 対応するトラックなし #{counts[:not_found]}件 / 保存失敗 #{counts[:failed]}件 / 失敗 #{counts[:error]}件"
    puts "分解されなかったものは、管理画面のアーティスト一覧「連名（未分解）」から手で分解してください。" if (counts[:not_found] + counts[:failed]).positive?
  end

  # rake_task.yml（本番での手動実行）は環境変数を渡せないため、確認用は別のタスクにしている
  desc "名前が連名の形のアーティストを、曲の Spotify トラックからメンバーに分解する（#78）"
  task decompose_joint_artists: :environment do
    decompose_joint_artists.call(dry_run: false)
  end

  desc "spotify:decompose_joint_artists の結果を、保存せずに一覧で確認する"
  task preview_joint_artists: :environment do
    decompose_joint_artists.call(dry_run: true)
  end
end
