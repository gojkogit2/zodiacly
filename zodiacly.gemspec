# frozen_string_literal: true

require_relative "lib/zodiacly/version"

Gem::Specification.new do |spec|
  spec.name = "zodiacly"
  spec.version = Zodiacly::VERSION
  spec.authors = ["Gojko"]
  spec.email = ["gojko1980@gmail.com"]

  spec.summary = "Ruby helper for fetching NASA/JPL ephemeris data and formatting astrology-friendly planetary positions."
  spec.description = "Zodiacly is a small Ruby library that fetches public NASA/JPL Horizons ephemeris data and converts it into astrology-friendly output (ecliptic longitude, zodiac sign, retrograde flag, and simple speed estimates) for common bodies like Sun and Moon. Designed for server-side use with caching."
  spec.homepage = "https://zodiacly.app"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/gojkogit2/zodiacly"
  spec.metadata["changelog_uri"] = "https://github.com/gojkogit2/zodiacly/blob/main/CHANGELOG.md"
  spec.metadata["bug_tracker_uri"] = "https://github.com/gojkogit2/zodiacly/issues"

  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[Gemfile .gitignore .rspec spec/ .idea/]) ||
        f.end_with?(".DS_Store") ||
        f.end_with?(".gem")
    end
  end

  spec.bindir = "bin"
  spec.executables = ["zodiacly"]
  spec.require_paths = ["lib"]

  spec.add_dependency "httparty", "~> 0.21"
  spec.add_dependency "csv", "~> 3.3"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.10"
end
