require_relative "boot"
require_relative "keys"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Sms2nostr
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    config.settings = config_for(:settings)

    raise "Error: Set the relays in config/settings.yml" unless Rails.application.config.settings[:relays]

    if Rails.application.config.settings[:sos_mode]
      raise "Error: Set the sms2nostr_host in config/settings.yml" unless Rails.application.config.settings[:sms2nostr_host]
      raise "Error: Set the sms2nostr_nsec in config/settings.yml" unless Rails.application.config.settings[:sms2nostr_nsec]
    end

  end
end
