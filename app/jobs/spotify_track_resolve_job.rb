class SpotifyTrackResolveJob < ApplicationJob
  queue_as :default

  # 見つからなかった曲を次に照合するまでの間隔（回数ごと。最後の値を以降も使う）。
  # 後から配信が始まる曲や、アーティストの Spotify ID が後から埋まる曲を拾い直すため
  RETRY_INTERVALS = [ 1.day, 1.week, 1.month ].freeze

  def perform(song_id)
    song = Song.find_by(id: song_id)
    return unless song

    link = Spotify::TrackResolver.call(song: song)

    if link
      song.platform_link_attempts.spotify.delete_all
      Rails.logger.info "[SpotifyTrackResolveJob] song_id=#{song_id} resolved track_id=#{link.platform_track_id}"
    else
      record_not_found(song)
      Rails.logger.info "[SpotifyTrackResolveJob] song_id=#{song_id} no match"
    end
  rescue Spotify::Client::Error => e
    # API の障害・制限は「見つからない」と区別し、記録を進めずに次の定期実行でやり直す
    Rails.logger.warn "[SpotifyTrackResolveJob] song_id=#{song_id} error=#{e.message}"
  end

  private

    def record_not_found(song)
      attempt = song.platform_link_attempts.find_or_initialize_by(platform: :spotify)
      now = Time.current
      interval = RETRY_INTERVALS[[ attempt.attempts_count, RETRY_INTERVALS.size - 1 ].min]
      attempt.update!(attempts_count: attempt.attempts_count + 1, last_attempted_at: now, next_attempt_at: now + interval)
    end
end
