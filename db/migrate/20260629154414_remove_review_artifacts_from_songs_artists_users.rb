class RemoveReviewArtifactsFromSongsArtistsUsers < ActiveRecord::Migration[8.1]
  def change
    remove_column :songs, :approve_count, :integer, default: 0, null: false
    remove_column :songs, :reject_count, :integer, default: 0, null: false
    remove_column :songs, :last_reviewed_at, :datetime

    remove_column :artists, :approve_count, :integer, default: 0, null: false
    remove_column :artists, :reject_count, :integer, default: 0, null: false
    remove_column :artists, :last_reviewed_at, :datetime

    remove_column :users, :trusted_count, :integer, default: 0, null: false
  end
end
