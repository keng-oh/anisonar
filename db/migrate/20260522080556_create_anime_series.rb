class CreateAnimeSeries < ActiveRecord::Migration[8.1]
  def change
    create_table :anime_series do |t|
      t.string :annict_series_id
      t.string :name, null: false
      t.string :name_en

      t.timestamps
    end
    add_index :anime_series, :annict_series_id, unique: true
  end
end
