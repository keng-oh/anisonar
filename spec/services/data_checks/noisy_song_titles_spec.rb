require 'rails_helper'

RSpec.describe DataChecks::NoisySongTitles do
  it "曲名に混入物がある曲を拾い、当たった文字列を示す" do
    song = create(:song, title: "青春コンプレックス (TV size)")

    findings = described_class.call
    expect(findings.map(&:record)).to eq([ song ])
    expect(findings.first.detail).to include("TV size")
  end

  it "混入物の無い曲は拾わない" do
    create(:song, title: "青春コンプレックス")
    create(:song, title: "Institution")

    expect(described_class.call).to be_empty
  end

  it "off vocal・カラオケも拾う" do
    a = create(:song, title: "曲 -off vocal-")
    b = create(:song, title: "曲（カラオケ）")

    expect(described_class.call.map(&:record)).to contain_exactly(a, b)
  end
end
