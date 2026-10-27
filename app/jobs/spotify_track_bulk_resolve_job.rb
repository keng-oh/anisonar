# Spotify に紐づいていない曲を定期的に照合する（楽曲取り込みとは切り離して行う）。
# まだ照合していない曲を優先し、残りの枠で再照合の時期が来た曲を照合する。
class SpotifyTrackBulkResolveJob < ApplicationJob
  queue_as :default

  BATCH_SIZE = 50
  # Spotify のレート制限に当たらないよう、1曲ずつ間隔を空けて照合する
  INTERVAL = 2.seconds

  def perform
    songs = Song.spotify_untried.order(:id).limit(BATCH_SIZE).to_a
    if songs.size < BATCH_SIZE
      due = Song.spotify_not_found.where(id: PlatformLinkAttempt.spotify.due.select(:song_id))
      songs += due.order(:id).limit(BATCH_SIZE - songs.size).to_a
    end

    songs.each_with_index { |song, i| SpotifyTrackResolveJob.set(wait: i * INTERVAL).perform_later(song.id) }
    Rails.logger.info "[SpotifyTrackBulkResolveJob] enqueued #{songs.size} SpotifyTrackResolveJob(s)."
  end
end
