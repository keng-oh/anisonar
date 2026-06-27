class CoverImageBulkResolveJob < ApplicationJob
  queue_as :default
  sidekiq_options retry: 3

  BATCH_SIZE = 50

  def perform
    animes = Anime.where(cover_image_url: [ nil, "" ])
                  .order(watchers_count: :desc)
                  .limit(BATCH_SIZE)

    animes.each_with_index { |anime, i| CoverImageResolveJob.set(wait: i * 2.seconds).perform_later(anime.id) }
    Rails.logger.info "[CoverImageBulkResolveJob] enqueued #{animes.size} CoverImageResolveJob(s)."
  end
end
