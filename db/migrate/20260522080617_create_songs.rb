class CreateSongs < ActiveRecord::Migration[8.1]
  def change
    create_table :songs do |t|
      t.string :title, null: false
      t.references :artist, null: false, foreign_key: true
      t.integer :song_type, null: false, default: 0
      t.integer :status, null: false, default: 0
      t.string :registered_by, null: false, default: "ai"
      t.integer :approve_count, null: false, default: 0
      t.integer :reject_count, null: false, default: 0
      t.datetime :last_reviewed_at
      t.text :notes

      t.timestamps
    end
  end
end
