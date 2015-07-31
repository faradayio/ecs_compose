# -*- coding: utf-8 -*-

require 'colorize'
require 'json'
require 'open3'
require 'tempfile'

module EcsCompose
  # Interfaces to the 'aws ecs' subcommand provided by the awscli Python
  # package from Amazon.  There might be a Ruby gem (like fog) that can do
  # some of this now, but Amazon keeps the awscli tool up to date, and ECS
  # is still very new.
  module Ecs
    # Run `aws ecs` with the specified arguments.
    def self.run(*args)
      command = ["aws", "ecs"] + args + ["--output", "json"]
      puts "→ #{command.join(' ').blue}"
      stdout, status = Open3.capture2(*command)
      if status != 0
        raise "Error running: #{command.inspect}"
      end
      JSON.parse(stdout)
    end

    # Register the specified task definition (passed as JSON data).
    def self.register_task_definition(json)
      # Dump our task definition to a tempfile so we have access to the
      # more complete set of arguments that are only available in file
      # mode.
      family = JSON.parse(json).fetch("family")
      Tempfile.open(['task-definition', '.json']) do |f|
        f.write(json)
        f.close()
        run("register-task-definition",
            "--cli-input-json", "file://#{f.path}")
      end
    end

    # Update the specified service.  Sample args: `"frontend"`,
    # `"frontend:7"`.
    def self.update_service(service, task_definition)
      run("update-service",
          "--service", service,
          "--task-definition", task_definition)
    end

    # Update the specified service, passing in a new task definition in
    # JSON format.
    def self.update_service_with_json(service, json)
      reg = register_task_definition(json)["taskDefinition"]
      task_def = "#{reg['family']}:#{reg['revision']}"
      update_service(service, task_def)
    end
  end
end
