class RemoveUrlFromCrawlRequests < ActiveRecord::Migration[8.1]
  def change
    remove_column :crawl_requests, :url, :string
  end
end
