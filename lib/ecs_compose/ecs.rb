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
    def self.update_service(cluster, service, task_definition)
      run("update-service",
          "--cluster", cluster,
          "--service", service,
          "--task-definition", task_definition)
    end

    # Update the specified service.  Sample args: `"frontend"`, `3`.
    def self.update_service_desired_count(cluster, service, desired_count)
      run("update-service",
          "--cluster", cluster,
          "--service", service,
          "--desired-count", desired_count.to_s)
    end

    # Run a one-off task.  Sample args: `"migrator:1"`.  The overrides may
    # be specified in the JSON format used by `aws ecs run-task`.
    def self.run_task(cluster, task_definition,
                      started_by: nil,
                      overrides_json: nil)
      extra_args = []
      extra_args.concat(["--overrides", overrides_json]) if overrides_json
      extra_args.concat(["--started-by", started_by]) if started_by
      run("run-task",
          "--cluster", cluster,
          "--task-definition", task_definition,
          *extra_args)
    end

    # Wait until all of the specified services have reached a stable state.
    # Returns nil.
    def self.wait_services_stable(cluster, services)
      run("wait", "services-stable",
          "--cluster", cluster,
          "--services", *services)
    end

    # Wait until all of the specified tasks have stopped.  Returns nil.
    def self.wait_tasks_stopped(cluster, arns)
      run("wait", "tasks-stopped",
          "--cluster", cluster,
          "--tasks", *arns)
    end

    # Describe a set of services as JSON.
    def self.describe_services(cluster, services)
      run("describe-services",
          "--cluster", cluster,
          "--services", *services)
    end

    # Describe a set of tasks as JSON.
    def self.describe_tasks(cluster, arns)
      run("describe-tasks",
          "--cluster", cluster,
          "--tasks", *arns)
    end
  end
end
