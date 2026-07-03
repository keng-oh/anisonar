class ExtractAlbumsFromPlatformLinks < ActiveRecord::Migration[8.1]
  def up
    create_table :albums do |t|
      t.string :spotify_album_id, null: false
      t.string :name, null: false
      t.string :image_url
      t.string :release_date
      t.timestamps
    end
    add_index :albums, :spotify_album_id, unique: true

    add_reference :songs, :album, foreign_key: true

    execute <<~SQL
      INSERT INTO albums (spotify_album_id, name, image_url, release_date, created_at, updated_at)
      SELECT DISTINCT ON (album_platform_id)
        album_platform_id, album_name, album_image_url, album_release_date, NOW(), NOW()
      FROM platform_links
      WHERE album_platform_id IS NOT NULL
        AND album_name IS NOT NULL
    SQL

    execute <<~SQL
      UPDATE songs
      SET album_id = albums.id
      FROM platform_links
      JOIN albums ON albums.spotify_album_id = platform_links.album_platform_id
      WHERE platform_links.song_id = songs.id
    SQL

    remove_column :platform_links, :album_name
    remove_column :platform_links, :album_image_url
    remove_column :platform_links, :album_platform_id
    remove_column :platform_links, :album_release_date
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
