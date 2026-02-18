# frozen_string_literal: true

require "time"
require "csv"
require "httparty"

module Zodiacly
  # Minimal wrapper for NASA/JPL Horizons API.
  # Docs: https://ssd-api.jpl.nasa.gov/doc/horizons.html
  class HorizonsClient
    include HTTParty
    base_uri "https://ssd.jpl.nasa.gov/api"

    DEFAULTS = {
      "format" => "json",
      "MAKE_EPHEM" => "'YES'",
      "OBJ_DATA" => "'NO'"
    }.freeze

    def fetch(params)
      res = self.class.get("/horizons.api", query: DEFAULTS.merge(params))
      unless res.success?
        raise Zodiacly::Error, "Horizons HTTP #{res.code}: #{res.body.to_s[0..300]}"
      end

      json = res.parsed_response
      if json.is_a?(Hash) && json["error"]
        raise Zodiacly::Error, "Horizons error: #{json["error"]}"
      end

      json
    end

    # Fetch vectors (position+velocity) in the ecliptic plane for a single instant.
    #
    # Returns the full JSON payload; the ephemeris text is inside json["result"].
    def vectors(command:, center:, time_utc:)
      # Horizons is picky about timestamp formats. Using START/STOP with a short window
      # avoids TLIST parsing issues with ISO8601 "T...Z".
      start_t = ensure_utc_horizons(time_utc)
      stop_t  = ensure_utc_horizons(Time.parse(time_utc.to_s).utc + 60) # +60s

      fetch(
        "COMMAND" => "'#{command}'",
        "CENTER" => "'#{center}'",
        "EPHEM_TYPE" => "'VECTORS'",
        "REF_PLANE" => "'ECLIPTIC'",
        "CSV_FORMAT" => "'YES'",
        "VEC_TABLE" => "'2'",
        "START_TIME" => "'#{start_t}'",
        "STOP_TIME" => "'#{stop_t}'",
        "STEP_SIZE" => "'1 m'"
      )
    end

    private

    def ensure_utc_horizons(time_utc)
      # Example acceptable format: "2026-02-07 19:53:27"
      Time.parse(time_utc.to_s).utc.strftime("%Y-%m-%d %H:%M:%S")
    end
  end

  # Convenience module wrapper, as requested: Zodiacly::Horizons.fetch(...)
  module Horizons
    module_function

    def client
      @client ||= HorizonsClient.new
    end

    def fetch(params)
      client.fetch(params)
    end

    def vectors(command:, center:, time_utc:)
      client.vectors(command: command, center: center, time_utc: time_utc)
    end
  end
end