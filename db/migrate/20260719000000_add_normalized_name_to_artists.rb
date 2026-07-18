class AddNormalizedNameToArtists < ActiveRecord::Migration[8.1]
  # 表示名は NameFormatter で整えつつ、重複判定は表記揺れを無視した比較キーで行うため、
  # キーをカラムとして保持する（SQLではNFKC正規化ができないため照合をSQL式で表現できない）。
  def up
    add_column :artists, :normalized_name, :string
    add_column :artists, :normalized_name_kana, :string

    formatted = 0
    Artist.reset_column_information
    Artist.find_each do |artist|
      name = NameFormatter.call(artist.name)
      name_kana = NameFormatter.call(artist.name_kana)
      formatted += 1 if name != artist.name || name_kana != artist.name_kana

      artist.update_columns(
        name: name,
        name_kana: name_kana,
        normalized_name: NameNormalizer.call(name),
        normalized_name_kana: name_kana.presence && NameNormalizer.call(name_kana)
      )
    end
    say "backfilled artists=#{Artist.count} (display name changed: #{formatted})"

    change_column_null :artists, :normalized_name, false
    add_index :artists, :normalized_name
    add_index :artists, :normalized_name_kana
  end

  def down
    remove_column :artists, :normalized_name
    remove_column :artists, :normalized_name_kana
  end
end
