class HomeController < ApplicationController
  include Pagy::Method

  SHELF_PAGE_SIZE = 48

  def index
    # 以前はトップページで検索していたので、古い検索 URL は検索ページへ送る
    if params[:q].present? || params[:season].present?
      redirect_to animes_path(params.permit(:q, :season))
      return
    end

    shelf = Songs::ShelfQuery.call.includes(:artist, :album, :platform_links)
    @pagy, @songs = pagy(:offset, shelf, limit: SHELF_PAGE_SIZE)
  end
end
