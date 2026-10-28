class HomeController < ApplicationController
  include Pagy::Method

  def index
    # 以前はトップページで検索していたので、古い検索 URL は検索ページへ送る
    if params[:q].present? || params[:season].present?
      redirect_to animes_path(params.permit(:q, :season))
      return
    end

    # 続きは棚の端に近づいたときに ShelfSongsController から読み込む
    @pagy, @songs = pagy(:countless, ShelfSongsController.shelf_songs, limit: ShelfSongsController::BATCH_SIZE, page: 1)
  end
end
