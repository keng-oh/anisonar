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

  SONG_STATUS_BADGE_CLASSES = { "pending" => "badge-warning", "reviewing" => "badge-info", "approved" => "badge-success", "rejected" => "badge-error" }.freeze
  SONG_STATUS_LABELS = { "pending" => "承認待ち", "reviewing" => "レビュー中", "approved" => "承認済み", "rejected" => "否認" }.freeze

  def song_status_badge_class(status)
    SONG_STATUS_BADGE_CLASSES.fetch(status.to_s, "badge-ghost")
  end

  def song_status_label(status)
    SONG_STATUS_LABELS.fetch(status.to_s, status.to_s)
  end
end
