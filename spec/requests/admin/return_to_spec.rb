require 'rails_helper'

RSpec.describe "編集画面からの戻り先", type: :request do
  before { sign_in create(:user, :admin) }

  let(:anime) { create(:anime, season: "2024-winter") }
  let(:anime_list) { "/admin/animes?year=2025&page=2" }

  describe "アニメの更新" do
    it "return_to の一覧へ戻る" do
      patch admin_anime_path(anime), params: { anime: { title: "新" }, return_to: anime_list }
      expect(response).to redirect_to(anime_list)
    end

    it "return_to が無い・別のパス・外部 URL なら条件なしの一覧へ戻る" do
      [ nil, "/admin/songs/all?q=a", "https://evil.example/admin/animes", "//evil.example/admin/animes", "http://[bad" ].each do |value|
        patch admin_anime_path(anime), params: { anime: { title: "新" }, return_to: value }.compact
        expect(response).to redirect_to(admin_animes_path), "return_to=#{value.inspect}"
      end
    end

    it "年と季節から season を保存する" do
      patch admin_anime_path(anime), params: { anime: { season_year: "2025", season_name: "spring" } }
      expect(anime.reload.season).to eq("2025-spring")
    end

    it "年を空にするとシーズン未設定になる" do
      patch admin_anime_path(anime), params: { anime: { season_year: "", season_name: "spring" } }
      expect(anime.reload.season).to be_nil
    end

    it "保存に失敗した再表示で return_to が残る" do
      patch admin_anime_path(anime), params: { anime: { title: "" }, return_to: anime_list }
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include('name="return_to"')
      expect(response.body).to include(CGI.escapeHTML(anime_list))
    end

    it "クロールキューへ追加しても return_to を引き継ぐ" do
      post enqueue_crawl_request_admin_anime_path(anime, return_to: anime_list)
      expect(response).to redirect_to(edit_admin_anime_path(anime, return_to: anime_list))
    end
  end

  describe "編集画面" do
    it "シーズンが年と季節のセレクトになり、「一覧に戻る」が戻り先を指す" do
      get edit_admin_anime_path(anime, return_to: anime_list)
      expect(response.body).to include('name="anime[season_year]"', 'name="anime[season_name]"')
      expect(response.body).to include(CGI.escapeHTML(anime_list))
    end

    it "一覧の編集リンクに return_to が付く" do
      anime
      get admin_animes_path(year: "2024")
      expect(response.body).to include(CGI.escape("/admin/animes?year=2024"))
    end
  end

  describe "楽曲" do
    let(:song) { create(:song) }
    let(:list) { "/admin/songs/all?song_type=op&page=3" }

    it "更新と削除の後に return_to の一覧へ戻る" do
      patch admin_song_path(song), params: { song: { title: "新" }, return_to: list }
      expect(response).to redirect_to(list)

      delete admin_song_path(song), params: { return_to: list }
      expect(response).to redirect_to(list)
    end

    it "外部 URL なら条件なしの一覧へ戻る" do
      patch admin_song_path(song), params: { song: { title: "新" }, return_to: "https://evil.example/admin/songs/all" }
      expect(response).to redirect_to(all_admin_songs_path)
    end
  end

  describe "アーティスト" do
    let(:artist) { create(:artist) }
    let(:list) { "/admin/artists?artist_type=person&page=2" }

    it "更新と削除の後に return_to の一覧へ戻る" do
      patch admin_artist_path(artist), params: { artist: { name: "新" }, return_to: list }
      expect(response).to redirect_to(list)

      delete admin_artist_path(artist), params: { return_to: list }
      expect(response).to redirect_to(list)
    end

    it "削除に失敗しても return_to を引き継ぐ" do
      create(:song, artist: artist)
      delete admin_artist_path(artist), params: { return_to: list }
      expect(response).to redirect_to(edit_admin_artist_path(artist, return_to: list))
    end

    it "所属アニメを保存できる" do
      anime = create(:anime)
      patch admin_artist_path(artist), params: { artist: { artist_type: "character", anime_id: anime.id } }
      expect(artist.reload.anime).to eq(anime)
    end
  end
end
