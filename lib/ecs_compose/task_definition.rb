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
    def register
      existing = Ecs.describe_task_definition(@name).fetch("taskDefinition")
      new = register_new.fetch("taskDefinition")
      use =
        if Compare.task_definitions_match?(existing, new)
          Plugins.plugins.each {|p| p.notify_skipping_deploy(existing, new) }
          existing
        else
          new
        end
      "#{use.fetch('family')}:#{use.fetch('revision')}"
    end

    # Register this task definition with ECS, and update the corresponding
    # service.
    def update(cluster)
      Ecs.update_service(cluster.name, name, register)
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
  end
end
