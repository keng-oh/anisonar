class CoverImageResolveJob < ApplicationJob
  queue_as :default

  def perform(anime_id)
    anime = Anime.find(anime_id)
    return if anime.cover_image_url.present?

    image_url = Anilist::CoverImageResolver.call(anime: anime)

    if image_url
      Rails.logger.info "[CoverImageResolveJob] anime_id=#{anime_id} resolved cover_image_url=#{image_url}"
    else
      Rails.logger.info "[CoverImageResolveJob] anime_id=#{anime_id} no match"
    end
  rescue Anilist::Client::Error => e
    Rails.logger.warn "[CoverImageResolveJob] anime_id=#{anime_id} error=#{e.message}"
  end
end
