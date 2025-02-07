source "https://rubygems.org"
ruby "3.4.1"

gem "rails", "~> 8.0.1"
gem "pg", "~> 1.1"
gem "propshaft"
gem "net-smtp", "0.5.0"
gem "puma", ">= 5.0"
gem "bootsnap", require: false
gem "hotwire-rails"
gem "importmap-rails"

group :development, :test do
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"
  gem "brakeman", require: false
  gem "rubocop-rails-omakase", require: false

  gem "rspec-rails", "~> 7.1.1"
  gem "factory_bot_rails"
end

group :development do
  gem "web-console"
end
