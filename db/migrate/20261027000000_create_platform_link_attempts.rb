class CreatePlatformLinkAttempts < ActiveRecord::Migration[8.1]
  # 配信サービスで見つからなかった曲を、間隔を空けて照合し直すための記録。
  # 記録が無いと、見つからない曲を定期ジョブのたびに照合し続けてしまう。
  def change
    create_table :platform_link_attempts do |t|
      t.references :song, null: false, foreign_key: true, index: false
      t.integer :platform, null: false
      t.integer :attempts_count, null: false, default: 0
      t.datetime :last_attempted_at, null: false
      t.datetime :next_attempt_at, null: false
      t.timestamps
    end
    add_index :platform_link_attempts, [ :song_id, :platform ], unique: true
    add_index :platform_link_attempts, [ :platform, :next_attempt_at ]
  end
end
