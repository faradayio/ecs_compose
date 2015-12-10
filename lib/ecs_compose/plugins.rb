require "ecs_compose/plugins/plugin"
require "ecs_compose/plugins/vault_plugin"

module EcsCompose
  # Plugins which allow ecs-compose to work better with various third-party
  # tools.
  module Plugins
    # A list of all enabled plugins.  Generated on demand to make it easier
    # to work with test suites.
    def self.plugins
      AVAILABLE_PLUGINS.select {|p| p.enabled? }.map {|p| p.new }
    end
  end
end

