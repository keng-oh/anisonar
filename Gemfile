source "https://rubygems.org"

gem "rails", "~> 8.1.3"
gem "propshaft"
gem "pg", "~> 1.1"
gem "puma", ">= 5.0"
gem "jsbundling-rails"
gem "turbo-rails"
gem "stimulus-rails"
gem "cssbundling-rails"
gem "jbuilder"

# Background jobs
gem "sidekiq", "~> 7.3", ">= 7.3.10"
gem "sidekiq-cron"
gem "redis", "~> 5.0"

# Cache / Cable (DB-backed)
gem "solid_cache"
gem "solid_cable"

# Components & UI
gem "view_component"

# HTTP client (Annict GraphQL, Spotify API)
gem "faraday"
gem "faraday-retry"

# Auth
gem "devise"

# メール送信（Resend）
gem "resend"

# N+1 detection
gem "bullet", group: :development

gem "tzinfo-data", platforms: %i[ windows jruby ]
gem "bootsnap", require: false
gem "kamal", require: false
gem "thruster", require: false

group :development, :test do
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"
  gem "rspec-rails"
  gem "factory_bot_rails"
  gem "bundler-audit", require: false
  gem "brakeman", require: false
  gem "rubocop-rails-omakase", require: false
end

group :development do
  gem "web-console"
  gem "annotaterb"
end

group :test do
  gem "vcr"
  gem "webmock"
  gem "shoulda-matchers", require: "shoulda/matchers"
end
