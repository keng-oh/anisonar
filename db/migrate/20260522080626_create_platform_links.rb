class CreatePlatformLinks < ActiveRecord::Migration[8.1]
  def change
    create_table :platform_links do |t|
      t.references :song, null: false, foreign_key: true
      t.integer :platform, null: false
      t.string :platform_track_id, null: false

      t.timestamps
    end
    add_index :platform_links, [ :song_id, :platform ], unique: true
  end
end
