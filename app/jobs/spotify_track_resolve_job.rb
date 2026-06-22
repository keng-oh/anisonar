class SpotifyTrackResolveJob < ApplicationJob
  queue_as :default

  def perform(song_id)
    song = Song.find(song_id)
    link = Spotify::TrackResolver.call(song: song)

    if link
      Rails.logger.info "[SpotifyTrackResolveJob] song_id=#{song_id} resolved track_id=#{link.platform_track_id}"
    else
      Rails.logger.info "[SpotifyTrackResolveJob] song_id=#{song_id} no match"
    end
  rescue Spotify::Client::Error => e
    Rails.logger.warn "[SpotifyTrackResolveJob] song_id=#{song_id} error=#{e.message}"
  end
end
