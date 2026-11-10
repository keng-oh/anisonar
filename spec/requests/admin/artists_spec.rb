require "rails_helper"

RSpec.describe "Admin::Artists", type: :request do
  before { sign_in create(:user, :admin) }

  describe "GET /admin/artists の種別の絞り込み" do
    let!(:actor) { create(:artist, name: "声優さん", artist_type: :person) }
    let!(:singer) { create(:artist, name: "歌手さん", artist_type: :person) }
    let!(:unit) { create(:artist, name: "ユニットさん", artist_type: :unit) }

    before do
      character = create(:artist, name: "キャラさん", artist_type: :character, anime: create(:anime))
      ArtistRelation.create!(from_artist: actor, to_artist: character, relation_type: :voice_of)
    end

    it "type=unit でユニットだけ" do
      get admin_artists_path(type: "unit")
      expect(response.body).to include("ユニットさん")
      expect(response.body).not_to include("歌手さん", "キャラさん")
    end

    it "type=voice_actor で voice_of を持つ person だけ" do
      get admin_artists_path(type: "voice_actor")
      expect(response.body).to include("声優さん")
      expect(response.body).not_to include("歌手さん", "ユニットさん", "キャラさん")
    end

    it "指定が無ければ全て" do
      get admin_artists_path
      expect(response.body).to include("歌手さん", "ユニットさん")
    end
  end
end
