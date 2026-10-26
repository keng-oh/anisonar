# 登録データの承認（レビュー）の仕組みは使わないことにしたため、テーブルとレビュアー権限を廃止する。
# AI が収集したデータを正とし、誤りは見つけたときに直す方針（2026-10）。
class DropReviews < ActiveRecord::Migration[8.1]
  def up
    drop_table :reviews

    # レビュアー権限（role = 1）は票の重みにしか使っていなかったので、一般ユーザーに戻す
    execute "UPDATE users SET role = 0 WHERE role = 1"
  end

  def down
    create_table :reviews do |t|
      t.integer :action, null: false
      t.text :comment
      t.bigint :reviewable_id, null: false
      t.string :reviewable_type, null: false
      t.references :user, null: false, foreign_key: true, index: true
      t.integer :weight, default: 1, null: false
      t.timestamps
    end
    add_index :reviews, [ :reviewable_type, :reviewable_id, :user_id ], unique: true, name: "index_reviews_on_reviewable_and_user"
    add_index :reviews, [ :reviewable_type, :reviewable_id ], name: "index_reviews_on_reviewable"
  end
end
