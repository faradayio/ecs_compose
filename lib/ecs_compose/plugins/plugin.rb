module EcsCompose
  module Plugins
    # A list of all available plugins.
    AVAILABLE_PLUGINS = []

    # Subclass this class and add it to `AVAILABLE_PLUGINS` to extend
    # `ecs_compose`.
    class Plugin
      # Does this plugin apply 
      def self.enabled?
        false
      end

      # Normalize a task definition for comparison.  This may remove
      # certain environment variables, for example, that are allowed to
      # vary from one deploy to the next.
      def normalize_task_definition!(taskdef)
      end

      # Called when we decide to skip a deploy because the previous version
      # of the software appears to still be valid.
      def notify_skipping_deploy(old, new)
      end
    end
  end
end
