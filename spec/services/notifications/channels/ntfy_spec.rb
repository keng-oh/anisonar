require 'rails_helper'
require 'webmock/rspec'

RSpec.describe Notifications::Channels::Ntfy do
  let(:url) { "https://ntfy.example.com/topic" }

  before { stub_request(:post, url) }

  it "既定ではエラー通知のヘッダで送る" do
    described_class.new(url:).notify("message")

    expect(WebMock).to have_requested(:post, url).with(body: "message", headers: { "Title" => "Anisonar Error", "Priority" => "high" })
  end

  it "タイトルと優先度を指定できる" do
    described_class.new(url:).notify("message", title: "Anisonar Info", priority: "default")

    expect(WebMock).to have_requested(:post, url).with(headers: { "Title" => "Anisonar Info", "Priority" => "default" })
  end

  it "日本語のタイトルは RFC 2047 の形で送る" do
    described_class.new(url:).notify("message", title: "データの点検")

    encoded = "=?UTF-8?B?#{Base64.strict_encode64('データの点検')}?="
    expect(WebMock).to have_requested(:post, url).with(headers: { "Title" => encoded })
  end

  it "URL 未設定なら何もしない" do
    described_class.new(url: nil).notify("message")

    expect(WebMock).not_to have_requested(:post, url)
  end
end
