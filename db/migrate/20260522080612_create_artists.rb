class CreateArtists < ActiveRecord::Migration[8.1]
  def change
    create_table :artists do |t|
      t.string :name, null: false
      t.string :name_kana
      t.integer :artist_type, null: false, default: 0
      t.references :anime, null: true, foreign_key: true
      t.string :image_url
      t.integer :status, null: false, default: 0
      t.integer :approve_count, null: false, default: 0
      t.integer :reject_count, null: false, default: 0
      t.datetime :last_reviewed_at
      t.references :created_by_user, foreign_key: { to_table: :users }, null: true
      t.references :updated_by_user, foreign_key: { to_table: :users }, null: true

      t.timestamps
    end
  end
end
