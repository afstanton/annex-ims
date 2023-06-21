# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV['RAILS_ENV'] ||= 'test'
require 'spec_helper'
require_relative '../config/environment'
require 'rspec/rails'

# Add additional requires below this line. Rails is not loaded until this point!
require 'webmock/rspec'
require 'factory_bot_rails'

# Requires supporting ruby files with custom matchers and macros, etc, in
# spec/support/ and its subdirectories. Files matching `spec/**/*_spec.rb` are
# run as spec files by default. This means that files in spec/support that end
# in _spec.rb will both be required and run as specs, causing the specs to be
# run twice. It is recommended that you do not name files matching this glob to
# end with _spec.rb. You can configure this pattern with the --pattern
# option on the command line or in ~/.rspec, .rspec or `.rspec-local`.
#
# The following line is provided for convenience purposes. It has the downside
# of increasing the boot-up time by auto-requiring all files in the support
# directory. Alternatively, in the individual `*_spec.rb` files, manually
# require only the support files necessary.
#
Dir[Rails.root.join('spec/support/**/*.rb')].each { |f| require f }

# Checks for pending migrations and applies them before tests are run.
# If you are not using ActiveRecord, you can remove these lines.
begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  puts e.to_s.strip
  exit 1
end

RSpec.configure do |config|
  # Tracker deprecation messages in each file
  if ENV['DEPRECATION_TRACKER']
    DeprecationTracker.track_rspec(
      config,
      shitlist_path: 'spec/support/deprecation_warning.shitlist.json',
      mode: ENV['DEPRECATION_TRACKER'],
      transform_message: -> (message) { message.gsub("#{Rails.root}/", '') }
    )
  end

  config.before(:suite) do
    DatabaseCleaner.clean_with(:truncation)
  end

  config.before(:all) do
    DatabaseCleaner.clean_with(:truncation)
  end

  config.before(:each) do |example|
    DatabaseCleaner.strategy = if example.metadata[:js]
                                 :truncation
                               else
                                 :transaction
                               end

    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end

  config.after(:all) do
    DatabaseCleaner.clean
  end

  config.before(:suite) do
    # Preload the fields for ActiveRecord objects to allow use of instance_double
    [
      Item,
      User,
      Request,
      Tray,
      Shelf
    ].each do |database_model|
      instance = database_model.new
      # The first attribute is id, which does not cause the methods to be built on the class
      field = instance.attributes.keys[1]
      # Trigger method missing on the instance which dynamically adds the methods to the class
      instance.send(field)

      # Reload all factories
      FactoryBot.reload

      # reindex models
      Item.reindex

      # and disable callbacks
      Searchkick.disable_callbacks
    end
  end

  config.around(:each, search: true) do |example|
    Searchkick.callbacks(nil) do
      example.run
    end
  end

  # Allow localhost connections for testing
  WebMock.disable_net_connect!(allow_localhost: true)

  # Create mock connection to Sentry.io
  config.before(:each) do
    stub_request(:post, /sentry.io/).
      to_return(status: 200, body: 'stubbed response', headers: {})
  end

  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = true
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!

  config.mock_with :rspec do |mocks|
    # Prevents you from mocking or stubbing a method that does not exist on
    # a real object. This is generally recommended, and will default to
    # `true` in RSpec 4.
    mocks.verify_partial_doubles = true
    mocks.allow_message_expectations_on_nil = true
  end

  # arbitrary gems may also be filtered via:
  # config.filter_gems_from_backtrace("gem name")

  # For Devise testing
  config.include Devise::Test::ControllerHelpers, type: :controller
  config.include FactoryBot::Syntax::Methods
  config.include ApiHelper

  config.include(Shoulda::Matchers::ActiveModel, type: :model)
  config.include(Shoulda::Matchers::ActiveRecord, type: :model)
end
