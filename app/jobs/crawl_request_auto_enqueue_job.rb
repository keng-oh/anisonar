# 処理待ちのクロール依頼が少なくなったら、未依頼のアニメを補充する（n8n が順に処理する）。
# 最近の作品と人気の作品から半分ずつ選ぶ。
class CrawlRequestAutoEnqueueJob < ApplicationJob
  queue_as :default

  LOW_WATER = 5
  BATCH_SIZE = 10

  def perform
    pending = CrawlRequest.pending.count
    return if pending >= LOW_WATER

    recent = CrawlRequests::BulkEnqueueService.call(limit: BATCH_SIZE / 2, strategy: :recent)
    popular = CrawlRequests::BulkEnqueueService.call(limit: BATCH_SIZE - recent.size, strategy: :popular)
    Rails.logger.info "[CrawlRequestAutoEnqueueJob] pending=#{pending} enqueued recent=#{recent.size} popular=#{popular.size}"
  end
end
