class RemoveEpisodeRangeFromAnimeSongs < ActiveRecord::Migration[8.1]
  def change
    remove_column :anime_songs, :episode_range, :string
  end
end
