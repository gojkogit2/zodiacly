# frozen_string_literal: true

RSpec.describe Zodiacly::Zodiac do
  it "assigns correct zodiac signs at boundaries" do
    expect(described_class.sign_for_lon(0)).to eq(:aries)
    expect(described_class.sign_for_lon(29.999)).to eq(:aries)
    expect(described_class.sign_for_lon(30)).to eq(:taurus)
    expect(described_class.sign_for_lon(359.99)).to eq(:pisces)
    expect(described_class.sign_for_lon(360)).to eq(:aries)
  end
end


RSpec.describe Zodiacly::Ephemeris do
  let(:time) { Time.utc(2026, 2, 7, 0, 0, 0) }

  it "marks body as retrograde when speed is negative" do
    result = described_class.at(time, bodies: %i[jupiter])

    jupiter = result[:bodies][:jupiter]
    expect(jupiter).to have_key(:retrograde)
    expect(jupiter[:retrograde]).to be(true).or be(false)
    expect(jupiter[:speed]).to be_a(Float)

    # Retrograde definition: negative speed
    expect(jupiter[:retrograde]).to eq(jupiter[:speed].negative?)
  end

  it "returns all major bodies when bodies: :all is used" do
    result = described_class.at(time, bodies: :all)

    expect(result[:bodies].keys).to contain_exactly(
      :sun,
      :moon,
      :mercury,
      :venus,
      :mars,
      :jupiter,
      :saturn,
      :uranus,
      :neptune,
      :pluto
    )
  end
end