require 'rails_helper'

RSpec.describe Spotify::ArtistMatcher do
  let(:client) { instance_double(Spotify::Client, search_artist: [], search_track: []) }

  def match(name, titles: [])
    described_class.call(name: name, titles: titles, client: client)
  end

  def artist(id, name) = { "id" => id, "name" => name }
  def track(name, *artists) = { "name" => name, "artists" => artists }

  it "曲名が無ければ、正規化名が一致する候補をそのまま採用する" do
    allow(client).to receive(:search_artist).with("梶浦由記", limit: 5).and_return([ artist("x", "Other"), artist("k", "梶浦 由記") ])

    expect(match("梶浦由記")["id"]).to eq("k")
    expect(client).not_to have_received(:search_track)
  end

  it "曲で確かめられなくても、名前が一致する候補が1つだけなら採用する" do
    allow(client).to receive(:search_artist).and_return([ artist("k", "梶浦 由記") ])

    expect(match("梶浦由記", titles: [ "配信されていない曲" ])["id"]).to eq("k")
  end

  # 実際に「LiSA」の検索結果は BLACKPINK の「LISA」が1位で、正規化すると名前も一致する
  it "名前が一致する候補が複数あれば、曲で確かめられたほうを採用する" do
    lisa_bp = artist("bp", "LISA")
    lisa = artist("lisa", "LiSA")
    allow(client).to receive(:search_artist).and_return([ lisa_bp, lisa ])
    allow(client).to receive(:search_track).with(%(track:"紅蓮華" artist:"LiSA"), limit: 10)
      .and_return([ track("紅蓮華", lisa) ])

    expect(match("LiSA", titles: [ "紅蓮華" ])["id"]).to eq("lisa")
  end

  it "名前が一致する候補が複数あり、曲で確かめられなければ採用しない" do
    allow(client).to receive(:search_artist).and_return([ artist("bp", "LISA"), artist("lisa", "LiSA") ])

    expect(match("LiSA", titles: [ "紅蓮華" ])).to be_nil
    expect(match("LiSA")).to be_nil
  end

  it "連名は名前が一致しない単独名義の候補を採用しない" do
    yoshiki = artist("y", "YOSHIKI")
    allow(client).to receive(:search_artist).and_return([ yoshiki ])
    allow(client).to receive(:search_track).and_return([ track("Red Swan", yoshiki) ])

    expect(match("YOSHIKI feat. HYDE", titles: [ "Red Swan" ])).to be_nil
  end

  it "名前が一致しない候補は、その候補の曲として存在すれば採用する（英語名義）" do
    eir = artist("eir", "Eir Aoi")
    allow(client).to receive(:search_artist).and_return([ artist("x", "Someone"), eir ])
    allow(client).to receive(:search_track).with(%(track:"IGNITE" artist:"Someone"), limit: 10).and_return([])
    allow(client).to receive(:search_track).with(%(track:"IGNITE" artist:"Eir Aoi"), limit: 10)
      .and_return([ track("IGNITE - TV size", eir) ])

    expect(match("藍井エイル", titles: [ "IGNITE" ])["id"]).to eq("eir")
  end

  it "候補の曲が見つからなければ採用しない" do
    allow(client).to receive(:search_artist).and_return([ artist("x", "Someone") ])
    allow(client).to receive(:search_track).and_return([ track("別の曲", artist("x", "Someone")) ])

    expect(match("誰か", titles: [ "IGNITE" ])).to be_nil
  end

  it "曲名が一致しても別のアーティストのトラックなら採用しない" do
    allow(client).to receive(:search_artist).and_return([ artist("x", "Someone") ])
    allow(client).to receive(:search_track).and_return([ track("IGNITE", artist("y", "Cover Singer")) ])

    expect(match("誰か", titles: [ "IGNITE" ])).to be_nil
  end

  it "曲名が無ければ名前の一致だけで判定する" do
    allow(client).to receive(:search_artist).and_return([ artist("x", "Someone") ])

    expect(match("誰か")).to be_nil
    expect(client).not_to have_received(:search_track)
  end
end
