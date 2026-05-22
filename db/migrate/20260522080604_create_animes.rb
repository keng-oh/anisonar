class CreateAnimes < ActiveRecord::Migration[8.1]
  def change
    create_table :animes do |t|
      t.string :annict_id
      t.references :anime_series, null: true, foreign_key: true
      t.string :title, null: false
      t.string :title_en
      t.string :season
      t.integer :media_type, null: false, default: 0
      t.integer :series_order
      t.integer :status, null: false, default: 0
      t.string :cover_image_url

      t.timestamps
    end
    add_index :animes, :annict_id, unique: true
  end
end
