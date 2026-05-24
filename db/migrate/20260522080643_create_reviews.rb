class CreateReviews < ActiveRecord::Migration[8.1]
  def change
    create_table :reviews do |t|
      t.string :reviewable_type, null: false
      t.bigint :reviewable_id,   null: false
      t.references :user, null: false, foreign_key: true
      t.integer :action, null: false
      t.integer :weight, null: false, default: 1
      t.text :comment

      t.timestamps
    end
    add_index :reviews, [ :reviewable_type, :reviewable_id, :user_id ],
              unique: true, name: "index_reviews_on_reviewable_and_user"
    add_index :reviews, [ :reviewable_type, :reviewable_id ],
              name: "index_reviews_on_reviewable"
  end
end
