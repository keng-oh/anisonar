# トップページの棚の続き（曲の HTML 断片）を返す
class ShelfSongsController < ApplicationController
  include Pagy::Method

  BATCH_SIZE = 30

  def self.shelf_songs
    Songs::ShelfQuery.call.includes(:artist, :album, :platform_links)
  end

  def index
    # 件数は使わないので COUNT を発行しない countless にする
    @pagy, @songs = pagy(:countless, self.class.shelf_songs, limit: BATCH_SIZE)
    render layout: false
  end
end
