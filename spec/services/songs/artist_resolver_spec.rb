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

    context "Spotify側が別名義の場合" do
      let(:spotify_client) { instance_double(Spotify::Client) }
      let(:eir) { { "id" => "eir", "name" => "Eir Aoi" } }

      before do
        allow(spotify_client).to receive(:search_artist).with("藍井エイル", limit: 5).and_return([ eir ])
        allow(spotify_client).to receive(:search_track).and_return([])
      end

      it "同じ依頼で取り込む曲がその候補の曲として存在すれば、Spotify IDを付けて作成する" do
        allow(spotify_client).to receive(:search_track).with(%(track:"INNOCENCE" artist:"Eir Aoi"), limit: 10)
          .and_return([ { "name" => "INNOCENCE", "artists" => [ eir ] } ])

        result = resolve([
          { title: "IGNITE", artist_name: "藍井エイル", song_type: "op" },
          { title: "INNOCENCE", artist_name: "藍井エイル", song_type: "ed" }
        ])

        artist = Artist.find(result.songs_data.first[:artist_id])
        expect(artist.spotify_artist_id).to eq("eir")
        expect(result.songs_data.map { |d| d[:artist_id] }.uniq).to eq([ artist.id ])
      end

      it "既に同じSpotify IDのアーティストがいれば、名前が違ってもそれを再利用する" do
        existing = create(:artist, name: "Eir Aoi", spotify_artist_id: "eir")
        allow(spotify_client).to receive(:search_track).and_return([ { "name" => "IGNITE", "artists" => [ eir ] } ])

        result = resolve([ { title: "IGNITE", artist_name: "藍井エイル", song_type: "op" } ])

        expect(result.songs_data.first[:artist_id]).to eq(existing.id)
      end

      it "曲で裏付けが取れなければSpotify IDを付けない" do
        result = resolve([ { title: "IGNITE", artist_name: "藍井エイル", song_type: "op" } ])

        expect(Artist.find(result.songs_data.first[:artist_id]).spotify_artist_id).to be_nil
      end
    end
  end
end
