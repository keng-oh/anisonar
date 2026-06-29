class RemoveStatusFromSongsAndArtists < ActiveRecord::Migration[8.1]
  def change
    remove_column :songs, :status, :integer, default: 0, null: false
    remove_column :artists, :status, :integer, default: 0, null: false
  end
end
