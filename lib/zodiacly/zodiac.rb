# frozen_string_literal: true

module Zodiacly
  module Zodiac
    SIGNS = %i[
      aries taurus gemini cancer leo virgo
      libra scorpio sagittarius capricorn aquarius pisces
    ].freeze

    def self.sign_for_lon(lon)
      lon = lon % 360.0
      index = (lon / 30.0).floor
      SIGNS[index]
    end
  end
end