module EcsCompose
  module Plugins

    class VaultPlugin
      # We're enabled if we know about a vault server.
      def self.enabled?
        ENV.has_key?('VAULT_ADDR') && ENV.has_key?('VAULT_MASTER_TOKEN')
      end

      # Make sure that vault is loaded and configured.
      def initialize
        begin
          require 'vault' unless defined?(Vault)
        rescue
          STDERR.puts("VAULT_ADDR defined, but `vault` gem not available")
          exit(1)
        end
        Vault.address = ENV.fetch('VAULT_ADDR')
        Vault.token = ENV.fetch('VAULT_MASTER_TOKEN')
      end

      # Normalize a task definition for comparison by removing VAULT_TOKEN
      # from each of the containers' environments.
      def normalize_task_definition!(taskdef)
        containers = taskdef.fetch("containerDefinitions", [])
        containers.each do |container|
          env = container.fetch("environment", [])
          env.reject! {|v| v.fetch("name") == "VAULT_TOKEN" }
        end
      end

      # Called when we decide to skip a deploy because the previous version
      # of the software appears to still be valid.
      def notify_skipping_deploy(old, new)
        tokens = old
          .fetch("containerDefinitions", [])
          .map {|c| c.fetch("environment", []) }
          .flatten
          .select {|var| var.fetch("name") == "VAULT_TOKEN" }
          .map {|var| var.fetch("value") }
        puts "Renewing #{tokens.length} vault tokens"
        tokens.each {|tok| Vault.auth_token.renew(tok) }
      end
    end

    AVAILABLE_PLUGINS << VaultPlugin
  end
end
