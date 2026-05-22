class CreateArtistRelations < ActiveRecord::Migration[8.1]
  def change
    create_table :artist_relations do |t|
      t.references :from_artist, null: false, foreign_key: { to_table: :artists }
      t.references :to_artist, null: false, foreign_key: { to_table: :artists }
      t.integer :relation_type, null: false

      t.timestamps
    end
    add_index :artist_relations, [ :from_artist_id, :to_artist_id, :relation_type ], unique: true, name: "index_artist_relations_unique"
  end
end
