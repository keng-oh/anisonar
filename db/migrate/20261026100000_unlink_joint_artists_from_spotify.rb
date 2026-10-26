# spotify:link_artists（2026-10-26 本番実行）で、連名のアーティストにメンバー1人の Spotify ID を
# 誤って紐づけたため外す。ID とアーティストの組が一致するときだけ外し、その後に手動で直したものは触らない。
class UnlinkJointArtistsFromSpotify < ActiveRecord::Migration[8.1]
  WRONG_LINKS = {
    4  => "1VSGTuDTMQZ3aKjlDNVFYH", # 美樹さやか（喜多村英梨）、佐倉杏子（野中藍） -> 佐倉杏子
    7  => "4And4cn8zCQdoLger3jVvZ", # アクア、めぐみん、ダクネス -> アクア
    17 => "6Ft6iUd8wRclZv2vqqwJ1u", # 本間芽衣子、安城鳴子、鶴見知利子 -> 本間芽衣子
    50 => "3CxgaOL8qRDrhSrzrse2ql", # 椎名まゆり、椎名かがり -> 椎名まゆり
    53 => "2EWIKpC6npt0GTe1Cq1KDm"  # YOSHIKI feat. HYDE -> YOSHIKI
  }.freeze

  def up
    WRONG_LINKS.each do |artist_id, spotify_artist_id|
      execute <<~SQL.squish
        UPDATE artists SET spotify_artist_id = NULL, updated_at = NOW()
        WHERE id = #{artist_id} AND spotify_artist_id = #{connection.quote(spotify_artist_id)}
      SQL
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
