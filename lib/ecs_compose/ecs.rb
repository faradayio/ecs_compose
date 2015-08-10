# -*- coding: utf-8 -*-

require 'colorize'
require 'json'
require 'open3'
require 'shellwords'
require 'tempfile'

module EcsCompose
  # Interfaces to the 'aws ecs' subcommand provided by the awscli Python
  # package from Amazon.  There might be a Ruby gem (like fog) that can do
  # some of this now, but Amazon keeps the awscli tool up to date, and ECS
  # is still very new.
  #
  # These are intended to be very low-level wrappers around the actual
  # command-line tool.  Higher-level logic mostly belongs in
  # TaskDefinition.
  module Ecs
    # Run `aws ecs` with the specified arguments.
    def self.run(*args)
      command = ["aws", "ecs"] + args + ["--output", "json"]
      STDERR.puts "→ #{Shellwords.join(command).blue}"
      stdout, status = Open3.capture2(*command)
      if status != 0
        raise "Error running: #{command.inspect}"
      end
      if stdout.empty?
        nil
      else
        JSON.parse(stdout)
      end
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

    # Run a one-off task.  Sample args: `"migrator:1"`.  The overrides may
    # be specified in the JSON format used by `aws ecs run-task`.
    def self.run_task(task_definition, overrides_json: nil)
      extra_args = []
      extra_args.concat(["--overrides", overrides_json]) if overrides_json
      run("run-task",
          "--task-definition", task_definition,
          *extra_args)
    end

    # Wait until all of the specified services have reached a stable state.
    # Returns nil.
    def self.wait_services_stable(services)
      run("wait", "services-stable",
          "--services", *services)
    end

    # Wait until all of the specified tasks have stopped.  Returns nil.
    def self.wait_tasks_stopped(arns)
      run("wait", "tasks-stopped",
          "--tasks", *arns)
    end

    # Describe a set of tasks as JSON.
    def self.describe_tasks(arns)
      run("describe-tasks",
          "--tasks", *arns)
    end
  end
end
