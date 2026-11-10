require 'rails_helper'

RSpec.describe "管理画面の一覧", type: :request do
  let(:admin) { create(:user, :admin) }

  before { sign_in admin }

  describe "楽曲一覧" do
    let!(:op_song) { create(:anime_song, song_type: :op, anime: create(:anime, title: "星空ロケット", watchers_count: 5)).song }
    let!(:ed_song) { create(:anime_song, song_type: :ed, anime: create(:anime, title: "海辺の物語", watchers_count: 50)).song }
    let!(:series_song) { create(:series_song, song_type: :insert, anime_series: create(:anime_series, name: "魔法シリーズ")).song }

    it "種別で絞り込める" do
      get all_admin_songs_path(song_type: "ed")
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(ed_song.title)
      expect(response.body).not_to include(op_song.title)
    end

    it "アニメ名で絞り込める" do
      get all_admin_songs_path(anime_q: "星空")
      expect(response.body).to include(op_song.title)
      expect(response.body).not_to include(ed_song.title)
    end

    it "アニメの人気順で並べ替えられる" do
      get all_admin_songs_path(sort: "anime_popularity")
      expect(response).to have_http_status(:ok)
      expect(response.body.index(ed_song.title)).to be < response.body.index(op_song.title)
    end

    it "シリーズへの紐づけも表示される" do
      get all_admin_songs_path
      expect(response.body).to include("魔法シリーズ（シリーズ）")
    end

    it "許可リスト外の値でもエラーにならない" do
      get all_admin_songs_path(song_type: "x'; DROP TABLE songs;--", sort: "bogus")
      expect(response).to have_http_status(:ok)
    end

    it "編集リンクに戻り先が付く" do
      get all_admin_songs_path(song_type: "ed")
      expect(response.body).to include(CGI.escape("/admin/songs/all?song_type=ed"))
    end
  end

  describe "アーティスト一覧" do
    let!(:person) { create(:artist, name: "個人さん", artist_type: :person) }
    let!(:unit) { create(:artist, name: "ユニットさん", artist_type: :unit) }

    it "種別で絞り込める" do
      get admin_artists_path(artist_type: "unit")
      expect(response.body).to include("ユニットさん")
      expect(response.body).not_to include("個人さん")
    end

    it "曲数の多い順で並べ替えられる" do
      create_list(:song, 2, artist: unit)
      get admin_artists_path(sort: "songs_count")
      expect(response).to have_http_status(:ok)
      expect(response.body.index("ユニットさん")).to be < response.body.index("個人さん")
    end

    it "許可リスト外の種別でもエラーにならない" do
      get admin_artists_path(artist_type: "bogus")
      expect(response).to have_http_status(:ok)
    end
  end

  describe "クロール依頼の一覧" do
    let!(:star) { create(:crawl_request, anime: create(:anime, title: "星空ロケット"), status: :failed) }
    let!(:sea) { create(:crawl_request, anime: create(:anime, title: "海辺の物語"), status: :failed) }
    let!(:done) { create(:crawl_request, anime: create(:anime, title: "星空済み"), status: :done) }

    it "作品名と状態を組み合わせて絞り込める" do
      get crawl_requests_admin_integrations_path(status: "failed", q: "星空")
      expect(response.body).to include("星空ロケット")
      expect(response.body).not_to include("海辺の物語")
      expect(response.body).not_to include("星空済み")
    end

    it "やり直し・削除の後も状態・検索語・ページが保たれる" do
      post retry_admin_crawl_request_path(star, status: "failed", q: "星空", page: "2")
      expect(response).to redirect_to(crawl_requests_admin_integrations_path(status: "failed", q: "星空", page: "2"))

      delete admin_crawl_request_path(sea, status: "failed", q: "海辺")
      expect(response).to redirect_to(crawl_requests_admin_integrations_path(status: "failed", q: "海辺"))
    end
  end
end
