require 'rails_helper'
require 'webmock/rspec'

RSpec.describe Spotify::Client do
  let(:client) { described_class.new(client_id: "id", client_secret: "secret") }
  let(:cache) { ActiveSupport::Cache::MemoryStore.new }
  let(:search_url) { %r{\Ahttps://api\.spotify\.com/v1/search} }

  before do
    allow(Rails).to receive(:cache).and_return(cache)
    stub_request(:post, described_class::TOKEN_URL).to_return(status: 200, body: { access_token: "token" }.to_json, headers: { "Content-Type" => "application/json" })
  end

  it "検索結果のトラックを返す" do
    stub_request(:get, search_url).to_return(status: 200, body: { tracks: { items: [ { "id" => "t1" } ] } }.to_json, headers: { "Content-Type" => "application/json" })

    expect(client.search_track("曲")).to eq [ { "id" => "t1" } ]
  end

  context "429（レート制限）が返った場合" do
    # Retry-After を待つと Sidekiq のスレッドが止まり、楽曲の取り込みが進まなくなった（本番で発生）
    it "Retry-After が長ければ待たずに Error にし、解けるまでの時刻を記録する" do
      stub_request(:get, search_url).to_return(status: 429, headers: { "Retry-After" => "3600" })

      started = Time.current
      expect { client.search_track("曲") }.to raise_error(described_class::Error, /429/)
      expect(Time.current - started).to be < 5
      expect(described_class.rate_limited_until).to be_within(5.seconds).of(1.hour.from_now)
    end

    it "制限中は API を呼ばずに Error にする" do
      stub_request(:get, search_url).to_return(status: 429, headers: { "Retry-After" => "3600" })
      expect { client.search_track("曲") }.to raise_error(described_class::Error)

      expect { client.get_track("t1") }.to raise_error(described_class::Error, /レート制限中/)
      expect(a_request(:get, %r{/v1/tracks/})).not_to have_been_made
    end

    it "Retry-After が短ければ待ってやり直す" do
      stub_request(:get, search_url)
        .to_return({ status: 429, headers: { "Retry-After" => "0" } },
                   { status: 200, body: { tracks: { items: [] } }.to_json, headers: { "Content-Type" => "application/json" } })

      expect(client.search_track("曲")).to eq []
      expect(described_class.rate_limited_until).to be_nil
    end
  end
end
