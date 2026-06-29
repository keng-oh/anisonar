module ApplicationHelper
  def season_label(season)
    Anime.season_label(season)
  end

  def sidebar_link_class(active)
    [ "gap-2.5", (active ? "active font-medium" : nil) ].compact.join(" ")
  end

  SONG_TYPE_BADGE_CLASSES = { "op" => "badge-primary", "ed" => "badge-secondary", "insert" => "badge-accent", "image" => "badge-ghost", "soundtrack" => "badge-neutral", "other" => "badge-ghost" }.freeze
  SONG_TYPE_LABELS = { "op" => "OP", "ed" => "ED", "insert" => "挿入歌", "image" => "イメージソング", "soundtrack" => "サントラ", "other" => "その他" }.freeze

  def song_type_badge_class(song_type)
    SONG_TYPE_BADGE_CLASSES.fetch(song_type.to_s, "badge-ghost")
  end

  def song_type_label(song_type)
    SONG_TYPE_LABELS.fetch(song_type.to_s, "-")
  end

  ARTIST_TYPE_LABELS = { "person" => "個人", "unit" => "グループ", "character" => "キャラクター" }.freeze

  def artist_type_label(artist_type)
    ARTIST_TYPE_LABELS.fetch(artist_type.to_s, artist_type.to_s)
  end
end
