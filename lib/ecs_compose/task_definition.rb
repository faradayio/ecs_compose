module EcsCompose

  # Information required to create an ECS task definition, and commands to
  # act upon it.
  class TaskDefinition
    attr_reader :type, :name, :yaml

    # Create a new TaskDefinition.  The type should be either `:task` or
    # `:service`, the name should be both the name of the ECS task
    # definition and the corresponding ECS service (if any), and the YAML
    # should be `docker-compose`-format YAML describing the containers
    # associated with this task.
    def initialize(type, name, yaml)
      @name = name
      @type = type
      @yaml = yaml
    end

    # Register this task definition with ECS if it isn't already
    # registered.  Will create the task definition if it doesn't exist, and
    # add a new version of the task.  Returns a string of the form
    # `"name:revision"` identifying the task we registered, or an existing
    # task with the same properties.
    def register(deployed=nil)
      # Describe the version we're currently running.
      if deployed
        existing = Ecs.describe_task_definition(deployed)
          .fetch("taskDefinition")
      else
        existing = nil
      end

      # Register the new version.  We always need to do this, so that we
      # can compare two officially normalized versions of the same task,
      # including any fields added by Amazon.
      new = register_new.fetch("taskDefinition")

      # Decide whether we can re-use the existing registration.
      if existing && Compare.task_definitions_match?(existing, new) && !force?
        rev1 = "#{existing.fetch('family')}:#{existing.fetch('revision')}"
        rev2 = "#{new.fetch('family')}:#{new.fetch('revision')}"
        puts "Running copy of #{rev1} looks good; not updating to #{rev2}."
        Plugins.plugins.each {|p| p.notify_skipping_deploy(existing, new) }
        wanted = existing
      else
        wanted = new
      end
      "#{wanted.fetch('family')}:#{wanted.fetch('revision')}"
    end

    # Get the existing "PRIMARY" deployment for the ECS service
    # corresponding to this task definition, and return it in
    # `name:revision` format.  Returns `nil` if it can't find a primary
    # deployment.
    def primary_deployment(cluster)
      # Try to describe the existing service.
      description = begin
        Ecs.describe_services(cluster.name, [@name])
      rescue => e
        puts "Error: #{e}"
        nil
      end

      missing_service_warning = <<-STR
Can't find an existing service '#{name}'.  You'll probably need to
register one manually using the AWS console and set up any load balancers
you might need.
      STR

      if description.nil?
        puts missing_service_warning
        return nil
      end

      unless service = description.fetch("services")[0]
        puts missing_service_warning
        return nil
      end

      # Find the primary deployment.
      deployment = service.fetch("deployments").find do |d|
        d["status"] == "PRIMARY"
      end
      return nil if deployment.nil?

      # Extract a task definition `name:revision`.
      arn = deployment.fetch("taskDefinition")
      arn.split('/').last
    end

    # Register this task definition with ECS, and update the corresponding
    # service.
    def update(cluster)
      deployed = primary_deployment(cluster)
      Ecs.update_service(cluster.name, name, register(deployed))
      name
    end

    # Set the number of running copies of a service we want to have.
    def scale(cluster, count)
      Ecs.update_service_desired_count(cluster.name, name, count)
      name
    end

    # Wait for a set of services to reach a steady state.
    def self.wait_for_services(cluster, service_names)
      Ecs.wait_services_stable(cluster.name, service_names)
      # TODO: We never actually get here if the services don't stabilize,
      # because wait_services_stable will fail with `Waiter ServicesStable
      # failed: Max attempts`.  But we're keeping this code until we
      # implement event polling and our own version of waiting.
      descriptions = Ecs.describe_services(cluster.name, service_names)
      ServiceError.fail_if_not_stabilized(descriptions)
    end

    # Run this task definition as a one-shot ECS task, with the specified
    # overrides.
    def run(cluster, started_by: nil, **args)
      overrides_json = json_generator.generate_override_json(**args)
      info = Ecs.run_task(cluster.name, register,
                          started_by: started_by,
                          overrides_json: overrides_json)
      info.fetch("tasks")[0].fetch("taskArn")
    end

    # Wait for a set of tasks to finish, and raise an error if they fail.
    def self.wait_for_tasks(cluster, task_arns)
      Ecs.wait_tasks_stopped(cluster.name, task_arns)
      TaskError.fail_on_errors(Ecs.describe_tasks(cluster.name, task_arns))
    end

    # Generate ECS task definition JSON for this instance.
    def to_json
      json_generator.json
    end

    protected

    # Always register a task.  Called by our public `register` API.
    def register_new
      Ecs.register_task_definition(to_json)
    end

    # Return a JSON generator for this task.
    def json_generator
      @json_generator ||= JsonGenerator.new(name, yaml)
    end

    # Should we force a deploy?
    def force?
      # ENV[...] may return nil, but we're OK with that.
      ["1", "true", "yes"].include?(ENV['ECS_COMPOSE_FORCE_DEPLOY'])
    end
  end
end
