class AddAlbumInfoToPlatformLinks < ActiveRecord::Migration[8.1]
  def change
    add_column :platform_links, :album_platform_id, :string
    add_column :platform_links, :album_name, :string
    add_column :platform_links, :album_image_url, :string
    add_column :platform_links, :album_release_date, :string
  end
end
