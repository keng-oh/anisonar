class CreateCrawlRequests < ActiveRecord::Migration[8.1]
  def change
    create_table :crawl_requests do |t|
      t.references :anime, null: false, foreign_key: true
      t.string :url, null: false
      t.string :status, null: false, default: "pending"
      t.string :dify_document_id
      t.text :error_message

      t.timestamps
    end
    add_index :crawl_requests, :status
  end
end
