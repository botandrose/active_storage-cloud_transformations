RSpec.configure do |config|
  config.filter_run focus: true
  config.run_all_when_everything_filtered = true

  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!
end

require "bundler/setup"
require "active_support"
require "active_support/configuration_file"
require "image_processing/mini_magick"
require "byebug"
Dir["#{__dir__}/support/**/*.rb"].each { |f| require f }

ENV["RAILS_ENV"] ||= "test"
require_relative "dummy/config/application"

SERVICE_CONFIGURATIONS = begin
  ActiveSupport::ConfigurationFile.parse(File.expand_path("storage.yml", __dir__)).deep_symbolize_keys
rescue Errno::ENOENT
  puts "Missing service configuration file in spec/storage.yml"
  {}
end
Rails.configuration.active_storage.service_configurations = SERVICE_CONFIGURATIONS.stringify_keys

Rails.application.initialize!

ActiveStorage.logger = ActiveSupport::Logger.new(nil)
ActiveStorage.verifier = ActiveSupport::MessageVerifier.new("Testing")

RSpec.configure do |config|
  config.before do
    ActiveStorage::Current.host = "https://example.com"
  end

  config.after do
    ActiveStorage::Current.reset
  end
end

