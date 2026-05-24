class CreateSongs < ActiveRecord::Migration[8.1]
  def change
    create_table :songs do |t|
      t.string :title, null: false
      t.references :artist, null: false, foreign_key: true
      t.integer :status, null: false, default: 0
      t.integer :approve_count, null: false, default: 0
      t.integer :reject_count, null: false, default: 0
      t.datetime :last_reviewed_at
      t.text :notes
      t.references :created_by_user, foreign_key: { to_table: :users }, null: true
      t.references :updated_by_user, foreign_key: { to_table: :users }, null: true

      t.timestamps
    end
  end
end
