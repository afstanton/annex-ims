# frozen_string_literal: true

def next?
  File.basename(__FILE__) == 'Gemfile.next'
end

source 'https://rubygems.org'

group :application do
  if next?
    gem 'rails', '~> 6.0.6'
  else
    gem 'rails', '~> 6.0.6'
  end

  gem 'next_rails'

  gem 'bootsnap'
  gem 'coffee-rails'
  gem 'jbuilder', '~> 2.0'
  gem 'jquery-rails', '~> 4.3.5'
  gem 'mini_racer'
  gem 'pg', '~> 1.2.3'
  gem 'sassc-rails'
  gem 'turbolinks'
  gem 'uglifier', '>= 1.3.0'

  # UI
  gem 'autoprefixer-rails'
  gem 'bootstrap-datepicker-rails' # nice datepicker for Bootstrap
  gem 'bootstrap-sass', '~> 3.4.1'
  gem 'bootstrap_progressbar' # for a progress bar
  gem 'haml-rails'
  gem 'jquery-datatables-rails', '~> 3.4.0'
  gem 'kaminari' # For paginating results
  gem 'multi-select-rails' # Multiselect for Rails asset pipeline
  gem 'recurring_select', '3.0.1'

  # authentication
  gem 'devise', '4.8.1' # LOCKED until Rails 7 upgrade
  gem 'omniauth-oktaoauth'

  # logging
  gem 'sentry-raven'
  # gem 'bundle-audit'

  # external service interaction
  gem 'faraday', '~> 1.10'
  gem 'faraday_middleware'
  gem 'net-http'

  # For item search
  gem 'progress_bar'
  gem 'sunspot_rails' # , :git => "https://github.com/sunspot/sunspot.git"

  # background processing
  gem 'sneakers'

  # Bug/Security updates
  gem 'bigdecimal'
  gem 'ffi', '>= 1.9.24'
  gem 'loofah', '~> 2.3.1'
  gem 'rake', '~> 13.0'

  # === Not using ===
  gem 'multi_xml'
end

gem 'ice_cube' # For scheduling tasks
gem 'whenever', require: false # For cron tasks

group :deployment do
  # Use Capistrano for deployment
  gem 'capistrano', '= 3.11.2'
  gem 'capistrano-maintenance', '~> 1.0'
  gem 'capistrano-rails', '~> 1.1'
end

group :development, :test, :staging do
  gem 'faker', '~> 1.4'
  gem 'haml_lint', require: false
  gem 'rubocop', '= 0.75.0' # this is the latest version hound supports
  gem 'rubocop-rails'
end

group :development, :test do
  gem 'byebug'
  gem 'hesburgh_infrastructure', git: 'https://github.com/ndlib/hesburgh_infrastructure'
  gem 'rails-erd'
  gem 'spring'

  # We test with Rspec
  gem 'coveralls'
  gem 'database_cleaner', '~> 1.3' # For cleaning up the test database
  gem 'factory_bot_rails', '~> 4.8.2' # For mocking up objects
  gem 'rspec-rails', '~> 5.0.0'
  gem 'spring-commands-rspec'

  # So staging etc can use stand alone Solr
  gem 'sunspot_solr' # , :git => "https://github.com/sunspot/sunspot.git"

  gem 'thin', '~> 1.8.1'
  # gem 'eventmachine', '1.2.2' # not required, dependancy of thin

  # bundle exec rake doc:rails generates the API under doc/api.
  gem 'sdoc', '1.1.0'
end

group :test do
  gem 'rails-controller-testing'
  gem 'shoulda-matchers'
  gem 'simplecov'
  gem 'sunspot_matchers'
  gem 'webmock', '~> 3.7.6'
end

group :development do
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'letter_opener'
  gem 'web-console', '~> 3.0'
  # gem 'bullet'

  # ==== Remove after Rails 7 upgrade
  gem 'rails_layout' # Simple generators for layouts
end
