module ApplicationHelper
  def season_label(season)
    Anime.season_label(season)
  end

  def sidebar_link_class(active)
    [ "gap-2.5", (active ? "active font-medium" : nil) ].compact.join(" ")
  end

  SONG_TYPE_BADGE_CLASSES = { "op" => "badge-primary", "ed" => "badge-secondary", "insert" => "badge-accent", "image" => "badge-ghost", "soundtrack" => "badge-neutral", "other" => "badge-ghost" }.freeze

  def song_type_badge_class(song_type)
    SONG_TYPE_BADGE_CLASSES.fetch(song_type.to_s, "badge-ghost")
  end

  def song_type_label(song_type)
    I18n.t("enums.song_type.#{song_type}", default: "-")
  end

  def artist_type_label(artist_type)
    I18n.t("enums.artist_type.#{artist_type}", default: artist_type.to_s)
  end
end
