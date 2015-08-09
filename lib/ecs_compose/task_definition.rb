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
    def register
      EcsCompose::Ecs.register_task_definition(to_json)
    end

    # Register this task definition with ECS, and update the corresponding
    # service.
    def up
      EcsCompose::Ecs.update_service_with_json(name, to_json)
    end

    # Run this task definition as a one-shot ECS task, with the specified
    # overrides.
    def run(environment: {}, entrypoint: nil, command: nil)
      puts "environment: #{environment.inspect}"
      puts "entrypoint: #{entrypoint.inspect}"
      puts "command: #{command.inspect}"
      raise "Not yet implemented"
    end

    # Generate ECS task definition JSON for this instance.
    def to_json
      json_generator.json
    end

    protected

    # Return a JSON generator for this task.
    def json_generator
      @json_generator ||= EcsCompose::JsonGenerator.new(name, yaml)
    end
  end
end
