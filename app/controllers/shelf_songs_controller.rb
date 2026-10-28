# トップページの棚の続き（曲の HTML 断片）を返す
class ShelfSongsController < ApplicationController
  include Pagy::Method

  BATCH_SIZE = 30

  def self.shelf_songs(year:)
    Songs::ShelfQuery.call(year:).includes(:artist, :album, :platform_links)
  end

  def self.year_param(value)
    value.to_s[/\A\d{4}\z/]&.to_i
  end

  def index
    @year = self.class.year_param(params[:year])
    # 件数は使わないので COUNT を発行しない countless にする
    @pagy, @songs = pagy(:countless, self.class.shelf_songs(year: @year), limit: BATCH_SIZE)
    render layout: false
  end
end
