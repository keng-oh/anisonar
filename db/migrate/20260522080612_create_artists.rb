class CreateArtists < ActiveRecord::Migration[8.1]
  def change
    create_table :artists do |t|
      t.string :name, null: false
      t.string :name_kana
      t.integer :artist_type, null: false, default: 0
      t.references :anime, null: true, foreign_key: true
      t.string :image_url

      t.timestamps
    end
  end
end
