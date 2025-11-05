require "active_storage/cloud_transformations/version"
require "active_storage/cloud_transformations/config"
require "active_storage/cloud_transformations/crucible_helpers"

module ActiveStorage
  module CloudTransformations
    class Rails < ::Rails::Engine
    end

    def self.config
      @config ||= Config.new
    end

    def self.configure
      yield config
    end
  end
end

