require "rails_helper"

RSpec.describe "Admin::ArtistRelations", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:anime) { create(:anime) }
  let(:actor) { create(:artist, artist_type: :person) }
  let(:character) { create(:artist, artist_type: :character, anime: anime) }
  let(:unit) { create(:artist, artist_type: :unit) }

  context "管理者" do
    before { sign_in admin }

    it "声優に演じたキャラクターを追加できる" do
      expect {
        post admin_artist_relations_path(actor), params: { slot: "characters", other_artist_id: character.id }
      }.to change(ArtistRelation.voice_of, :count).by(1)
      expect(response).to redirect_to(edit_admin_artist_path(actor))
      expect(actor.voiced_characters).to contain_exactly(character)
    end

    it "ユニットにメンバーを新しく作って追加できる（同じ名前があれば再利用）" do
      post admin_artist_relations_path(unit), params: { slot: "members", name: "ぼっち", artist_type: "character", anime_id: anime.id }
      expect(unit.unit_members.map(&:name)).to eq [ "ぼっち" ]
      expect {
        post admin_artist_relations_path(unit), params: { slot: "members", name: "ぼっち", artist_type: "character" }
      }.not_to change(Artist, :count)
    end

    it "同じ名前の既存が種別違いで関係が成り立たないときは保存せず、理由を出す" do
      create(:artist, name: "同名", artist_type: :person)
      actor
      expect {
        post admin_artist_relations_path(actor), params: { slot: "characters", name: "同名", artist_type: "character", anime_id: anime.id }
      }.not_to change { [ Artist.count, ArtistRelation.count ] }
      expect(response).to redirect_to(edit_admin_artist_path(actor))
      expect(flash[:alert]).to include("キャラクター")
    end

    it "joint には関係を追加できない" do
      joint = create(:artist, artist_type: :joint)
      expect {
        post admin_artist_relations_path(joint), params: { slot: "members", other_artist_id: actor.id }
      }.not_to change(ArtistRelation, :count)
      expect(flash[:alert]).to be_present
    end

    it "関係を外せる" do
      relation = ArtistRelation.create!(from_artist: actor, to_artist: character, relation_type: :voice_of)
      expect { delete admin_artist_relation_path(character, relation) }.to change(ArtistRelation, :count).by(-1)
    end

    it "編集画面に関係の欄が出る" do
      ArtistRelation.create!(from_artist: actor, to_artist: character, relation_type: :voice_of)
      get edit_admin_artist_path(actor)
      expect(response.body).to include("演じたキャラクター", character.name)
    end
  end

  it "一般ユーザーはリダイレクトされ、追加できない" do
    sign_in create(:user)
    expect {
      post admin_artist_relations_path(actor), params: { slot: "characters", other_artist_id: character.id }
    }.not_to change(ArtistRelation, :count)
    expect(response).to redirect_to(root_path)
  end
end
