class AiSongResearchJob < ApplicationJob
  queue_as :default

  AI_USER_EMAIL = "ai@anisonar.internal".freeze

  def perform(anime_id)
    anime = Anime.find(anime_id)
    ai_user = User.find_by!(email: AI_USER_EMAIL)

    Rails.logger.info "[AiSongResearchJob] start anime_id=#{anime_id} title=#{anime.title}"

    research = Songs::AiResearcher.call(anime: anime)
    items = research[:items]
    Rails.logger.info "[AiSongResearchJob] researched #{items.size} items"

    songs_data = Songs::ArtistResolver.call(items: items, anime: anime)

    result = Songs::BulkSaveService.call(songs_data: songs_data, user: ai_user)

    Rails.logger.info "[AiSongResearchJob] saved=#{result.saved.size} failed=#{result.failed.size}"
    result.failed.each do |f|
      Rails.logger.warn "[AiSongResearchJob] failure: #{f[:messages].join(', ')} data=#{f[:data].inspect}"
    end

    result
  end
end
