class CreateAnimeSongs < ActiveRecord::Migration[8.1]
  def change
    create_table :anime_songs do |t|
      t.references :anime, null: false, foreign_key: true
      t.references :song, null: false, foreign_key: true
      t.string :song_type, null: false
      t.string :episode_range

      t.timestamps
    end
    add_index :anime_songs, [ :anime_id, :song_id ], unique: true
  end
end
