# frozen_string_literal: true

require "time"
require_relative "zodiac"
require_relative "horizons_client"
require "json"
require "digest"
require "fileutils"
require "tmpdir"

module Zodiacly
  class Ephemeris
    # Horizons target IDs (common major bodies)
    BODY_TO_COMMAND = {
      sun: "10",
      moon: "301",
      mercury: "199",
      venus: "299",
      mars: "499",
      jupiter: "599",
      saturn: "699",
      uranus: "799",
      neptune: "899",
      pluto: "999"
    }.freeze

    DEFAULT_BODIES = %i[sun moon].freeze

    # Public API: Zodiacly::Ephemeris.at(time, bodies:)
    #
    # bodies:
    #   - Array of symbols (e.g. %i[sun moon mars])
    #   - :all (for all supported major bodies)
    #
    # cache_ttl:
    #   - seconds to keep cached results (default: 3600)
    def self.at(time_utc = Time.now.utc, center: "500@399", bodies: DEFAULT_BODIES, cache_ttl: 3600)
      time = Time.parse(time_utc.to_s).utc
      iso  = time.iso8601

      bodies =
        if bodies == :all
          %i[
            sun moon mercury venus mars
            jupiter saturn uranus neptune pluto
          ]
        else
          Array(bodies).map(&:to_sym)
        end

      cache_key = Digest::SHA256.hexdigest([
        iso,
        center,
        bodies.sort.join(",")
      ].join("|"))

      cache_fetch(cache_key, cache_ttl) do
        results = {}

        bodies.each do |body|
          command = BODY_TO_COMMAND.fetch(body) do
            raise Zodiacly::Error, "Unknown body: #{body.inspect}. Known: #{BODY_TO_COMMAND.keys.join(", ")}"
          end

          json = Zodiacly::Horizons.vectors(command: command, center: center, time_utc: iso)
          vec  = parse_vectors(json)

          lon   = ecliptic_longitude_deg(vec[:x], vec[:y])
          speed = ecliptic_longitude_speed_deg_per_day(vec[:x], vec[:y], vec[:vx], vec[:vy])

          results[body] = {
            lon: lon.round(2),
            sign: Zodiacly::Zodiac.sign_for_lon(lon),
            retrograde: speed.negative?,
            speed: speed.round(4)
          }
        end

        {
          time_utc: iso,
          center: center,
          bodies: results
        }
      end
    end

    # ---- Parsing ----

    # Horizons JSON has a "result" string which contains a table between $$SOE and $$EOE.
    # With CSV_FORMAT=YES and VEC_TABLE=2, each row is CSV and includes x,y,z,vx,vy,vz.
    def self.parse_vectors(json)
      result = json.fetch("result") { raise Zodiacly::Error, "Horizons response missing 'result' key" }

      line = extract_soe_line(result)
      parts = line.split(",").map(&:strip)

      # We expect the last 6 CSV columns to be numeric x,y,z,vx,vy,vz (in km and km/s typically)
      nums = parts.last(6).map { |v| Float(v) }

      {
        x: nums[0],
        y: nums[1],
        z: nums[2],
        vx: nums[3],
        vy: nums[4],
        vz: nums[5]
      }
    rescue KeyError, ArgumentError => e
      raise Zodiacly::Error, "Failed to parse Horizons vectors: #{e.message}"
    end

    def self.extract_soe_line(result_text)
      start_idx = result_text.index("$$SOE")
      stop_idx  = result_text.index("$$EOE")
      raise Zodiacly::Error, "Horizons result missing $$SOE/$$EOE markers" unless start_idx && stop_idx

      block = result_text[(start_idx + 5)...stop_idx].strip
      # Take the first non-empty line
      line = block.lines.map(&:strip).find { |l| !l.empty? }
      raise Zodiacly::Error, "Horizons SOE block was empty" unless line
      line
    end

    # ---- Math ----

    def self.ecliptic_longitude_deg(x, y)
      rad = Math.atan2(y, x)
      deg = rad * 180.0 / Math::PI
      deg %= 360.0
      deg += 360.0 if deg.negative?
      deg
    end

    # Angular speed of longitude using planar angular velocity:
    # omega = (x*vy - y*vx) / (x^2 + y^2)  [rad/s]
    # convert to deg/day
    def self.ecliptic_longitude_speed_deg_per_day(x, y, vx, vy)
      r2 = (x * x) + (y * y)
      return 0.0 if r2.zero?

      omega = (x * vy - y * vx) / r2 # rad / s
      omega * (180.0 / Math::PI) * 86_400.0
    end

    def self.cache_fetch(key, ttl)
      dir = File.join(Dir.tmpdir, "zodiacly-cache")
      FileUtils.mkdir_p(dir)

      path = File.join(dir, "#{key}.json")

      if File.exist?(path) && (Time.now - File.mtime(path) < ttl)
        return JSON.parse(File.read(path), symbolize_names: true)
      end

      data = yield
      File.write(path, JSON.pretty_generate(data))
      data
    end
  end
end