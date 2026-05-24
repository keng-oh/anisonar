class CreateSeriesSongs < ActiveRecord::Migration[8.1]
  def change
    create_table :series_songs do |t|
      t.references :anime_series, null: false, foreign_key: true
      t.references :song, null: false, foreign_key: true
      t.integer :song_type, null: false, default: 0

      t.timestamps
    end

    add_index :series_songs, [ :anime_series_id, :song_id ], unique: true
  end
end
