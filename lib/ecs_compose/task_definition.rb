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

    # Register this task definition with ECS.  Will create the task
    # definition if it doesn't exist, and add a new version of the task.
    # Returns a string of the form `"name:revision"` identifying the task
    # we registered.
    def register
      reg = Ecs.register_task_definition(to_json)
        .fetch("taskDefinition")
      "#{reg.fetch('family')}:#{reg.fetch('revision')}"
    end

    # Register this task definition with ECS, and update the corresponding
    # service.
    def update
      Ecs.update_service(name, register)
      name
    end

    # Wait for a set of services to reach a steady state.
    def self.wait_for_services(service_names)
      Ecs.wait_services_stable(service_names)
      # TODO: Check for errors during stabilization.
    end

    # Run this task definition as a one-shot ECS task, with the specified
    # overrides.
    def run(**args)
      overrides_json = json_generator.generate_override_json(**args)
      info = Ecs.run_task(register, overrides_json: overrides_json)
      info.fetch("tasks")[0].fetch("taskArn")
    end

    # Wait for a set of tasks to finish, and raise an error if they fail.
    def self.wait_for_tasks(task_arns)
      Ecs.wait_tasks_stopped(task_arns)
      TaskError.fail_on_errors(Ecs.describe_tasks(task_arns))
    end

    # Generate ECS task definition JSON for this instance.
    def to_json
      json_generator.json
    end

    protected

    # Return a JSON generator for this task.
    def json_generator
      @json_generator ||= JsonGenerator.new(name, yaml)
    end
  end
end
