require 'rails_helper'

RSpec.describe Songs::ArtistResolver do
  let(:anime)   { create(:anime) }
  let!(:ai_bot) { create(:user, email: User::AI_USER_EMAIL) }

  # Spotify照合はこのサービスの関心事ではないため、常に該当なしを返すクライアントを注入する
  let(:spotify_client) { instance_double(Spotify::Client, search_artist: []) }

  def resolve(items)
    described_class.call(items: items, anime: anime, user: ai_bot, spotify_client: spotify_client)
  end

  describe "#call" do
    it "全itemが解決できる場合、songs_dataを返しfailedは空になる" do
      result = resolve([
        { title: "曲A", artist_name: "アーティストA", song_type: "op" },
        { title: "曲B", artist_name: "アーティストB", song_type: "ed" }
      ])

      expect(result.songs_data.map { |d| d[:title] }).to eq([ "曲A", "曲B" ])
      expect(result.failed).to be_empty
    end

    # 本来の不具合。以前は途中のitemで例外が飛ぶと呼び出し元まで伝播し、
    # 既にコミット済みのアーティストだけが曲に紐づかないまま残っていた
    it "一部のitemが失敗しても、残りのitemの解決を継続する" do
      result = resolve([
        { title: "曲A", artist_name: "アーティストA", song_type: "op" },
        { title: "曲B", artist_name: "",              song_type: "ed" },
        { title: "曲C", artist_name: "アーティストC", song_type: "insert" }
      ])

      expect(result.songs_data.map { |d| d[:title] }).to eq([ "曲A", "曲C" ])
      expect(result.failed.size).to eq(1)
      expect(result.failed.first[:item][:title]).to eq("曲B")
      expect(result.failed.first[:message]).to include("曲B")
    end

    it "失敗したitemのアーティストを作成しない" do
      expect {
        resolve([ { title: "曲B", artist_name: "", song_type: "ed" } ])
      }.not_to change(Artist, :count)
    end

    it "同一バッチ内の同名アーティストは1件しか作成しない" do
      expect {
        resolve([
          { title: "曲A", artist_name: "重複アーティスト", song_type: "op" },
          { title: "曲B", artist_name: "重複アーティスト", song_type: "ed" }
        ])
      }.to change(Artist, :count).by(1)
    end

    it "既存アーティストがいる場合は再利用する" do
      existing = create(:artist, name: "既存アーティスト")

      result = nil
      expect {
        result = resolve([ { title: "曲A", artist_name: "既存アーティスト", song_type: "op" } ])
      }.not_to change(Artist, :count)

      expect(result.songs_data.first[:artist_id]).to eq(existing.id)
    end
  end
end
