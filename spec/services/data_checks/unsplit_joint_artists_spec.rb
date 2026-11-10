require 'rails_helper'

RSpec.describe DataChecks::UnsplitJointArtists do
  it "区切りを含む person を拾い、分けた候補を示す" do
    artist = create(:artist, name: "鈴木このみ feat. Ashnikko", artist_type: :person)

    findings = described_class.call
    expect(findings.map(&:record)).to eq([ artist ])
    expect(findings.first.detail).to include("鈴木このみ", "Ashnikko")
  end

  it "joint・unit・区切りの無い名前は拾わない" do
    create(:artist, name: "A feat. B", artist_type: :joint)
    create(:artist, name: "MYTH & ROID", artist_type: :unit)
    create(:artist, name: "結束バンド", artist_type: :person)

    expect(described_class.call).to be_empty
  end
end
