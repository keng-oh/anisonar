require 'rails_helper'
require 'webmock/rspec'

RSpec.describe Notifications::Channels::Discord do
  let(:url) { "https://discord.example.com/webhook" }

  before { stub_request(:post, url) }

  it "既定ではメッセージだけを送る" do
    described_class.new(webhook_url: url).notify("message")

    expect(WebMock).to have_requested(:post, url).with(body: { content: "message" }.to_json)
  end

  it "タイトルがあれば先頭行に付ける" do
    described_class.new(webhook_url: url).notify("message", title: "タイトル")

    expect(WebMock).to have_requested(:post, url).with(body: { content: "タイトル\nmessage" }.to_json)
  end
end
