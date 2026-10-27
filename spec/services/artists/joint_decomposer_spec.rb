require 'rails_helper'

RSpec.describe Artists::JointDecomposer do
  include ActiveJob::TestHelper

  let(:user) { create(:user, role: :admin) }
  let(:joint) { create(:artist, name: "鈴木このみ feat. Ashnikko", spotify_artist_id: "konomi") }
  let!(:konomi) { create(:artist, name: "鈴木このみ") }
  let!(:song) { Song.create!(title: "Bursty Greedy Spider", artist: joint) }

  def decompose(members)
    described_class.call(artist: joint, members: members, user: user)
  end

  it "既存と新規のメンバーを credited_in で結び、連名として確定する" do
    result = nil
    expect {
      result = decompose([ { artist_id: konomi.id }, { name: "Ashnikko", artist_type: "person" } ])
    }.to have_enqueued_job(SpotifyTrackResolveJob).with(song.id)

    expect(result).to be_success
    expect(joint.reload).to be_joint
    expect(joint.credit_members.map(&:name)).to contain_exactly("鈴木このみ", "Ashnikko")
    expect(konomi.joint_credits).to contain_exactly(joint)
  end

  it "付いていた Spotify ID を外し、呼び出し側に返す" do
    result = decompose([ { artist_id: konomi.id }, { name: "Ashnikko", artist_type: "person" } ])

    expect(result.previous_spotify_artist_id).to eq "konomi"
    expect(joint.reload.spotify_artist_id).to be_nil
  end

  it "新しく作るメンバーと同じ名前のアーティストがあれば、それを使う" do
    expect {
      decompose([ { name: "鈴木 このみ", artist_type: "person" }, { name: "Ashnikko", artist_type: "person" } ])
    }.to change(Artist, :count).by(1)

    expect(joint.reload.credit_members).to include(konomi)
  end

  it "指定から外れたメンバーの関係を消す" do
    decompose([ { artist_id: konomi.id }, { name: "Ashnikko", artist_type: "person" } ])
    other = create(:artist, name: "別の人")

    decompose([ { artist_id: konomi.id }, { artist_id: other.id } ])

    expect(joint.reload.credit_members).to contain_exactly(konomi, other)
  end

  it "メンバーが2人に満たなければ何も変えない" do
    result = decompose([ { artist_id: konomi.id }, { artist_id: "" } ])

    expect(result).not_to be_success
    expect(joint.reload).to be_person
    expect(joint.credit_members).to be_empty
  end

  it "メンバーの保存に失敗したら、全体を取り消してエラーを返す" do
    result = decompose([ { artist_id: konomi.id }, { name: "キャラ（声優）", artist_type: "character", anime_id: "" } ])

    expect(result).not_to be_success
    expect(result.errors.first).to include("キャラ（声優）")
    expect(joint.reload).to be_person
    expect(Artist.find_by(name: "キャラ（声優）")).to be_nil
  end
end
