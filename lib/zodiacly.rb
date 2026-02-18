# frozen_string_literal: true

require_relative "zodiacly/version"
require_relative "zodiacly/zodiac"
require_relative "zodiacly/horizons_client"
require_relative "zodiacly/ephemeris"

module Zodiacly
  class Error < StandardError; end
end