class CreateReviews < ActiveRecord::Migration[8.1]
  def change
    create_table :reviews do |t|
      t.references :song, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.integer :action, null: false
      t.integer :weight, null: false, default: 1
      t.text :comment

      t.timestamps
    end
    add_index :reviews, [ :song_id, :user_id ], unique: true
  end
end
