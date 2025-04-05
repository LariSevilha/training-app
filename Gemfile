source "https://rubygems.org"
ruby "3.2.3"

gem "rails", "~> 7.2.0", ">= 7.0.4.3"
gem "pg"
gem 'rack-cors'
gem 'devise'  
gem 'pundit'
gem 'jwt'
gem 'active_model_serializers', '~> 0.10.0'
gem "puma", ">= 6.0"
gem 'bcrypt', '~> 3.1.7' 
gem "tzinfo-data", platforms: %i[ windows jruby ]
gem "solid_cache"
gem "solid_queue"
gem "solid_cable"
gem 'fcm'
gem "bootsnap", require: false
gem "kamal", require: false
gem "thruster", require: false

group :development, :test do
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"
  gem "brakeman", require: false
  gem "rubocop-rails-omakase", require: false
end

group :development do
  gem 'spring'
end