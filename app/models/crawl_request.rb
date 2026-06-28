class CrawlRequest < ApplicationRecord
  belongs_to :anime

  enum :status, { pending: "pending", crawling: "crawling", crawled: "crawled", extracting: "extracting", done: "done", failed: "failed" }
end
