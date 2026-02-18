# Zodiacly ♈︎

Zodiacly is a lightweight Ruby gem for calculating zodiac signs and basic astronomical ephemeris data.

It provides:

- ♈︎ Zodiac sign calculation (with correct boundary handling)
- ☀️ Major celestial body positions
- 🔁 Retrograde detection (based on negative speed)
- 🧮 Simple CLI interface

---

## Installation

Add to your Gemfile:

```bash
bundle add zodiacly
```

Or install directly:

```bash
gem install zodiacly
```

---

## Usage

### CLI – Ephemeris

```bash
zodiacly ephemeris --bodies all
```

Options:

- `--time` UTC time (ISO8601 or `now`)
- `--bodies` Comma-separated list (`sun,moon,mars`) or `all`
- `--version` Show gem version
- `--help` Show help

Example:

```bash
zodiacly ephemeris --time 2026-02-07T00:00:00Z --bodies sun,moon
```

---

## Ruby Usage

```ruby
require "zodiacly"

# Example zodiac usage
Zodiacly::Zodiac.sign_for(Date.new(1990, 3, 21))

# Example ephemeris usage
Zodiacly::Ephemeris.calculate(time: Time.now.utc, bodies: :all)
```

---

## Development

Run tests:

```bash
bundle exec rspec
```

Build gem:

```bash
gem build zodiacly.gemspec
```

Release:

```bash
bundle exec rake release
```

---

## License

MIT License.