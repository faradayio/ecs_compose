require "ecs_compose"
require "thor"

module EcsCompose
  # Our basic command-line interface.
  class CLI < Thor
    class_option(:services, type: :string,
                 desc: "A comma-separated list of containers to include. Defaults to all.")

    desc("conv FAMILY [YAML_FILE]",
         "Convert docker-compose.yml to ECS JSON format")
    def jsonify(family, yaml_file="docker-compose.yml")
      yaml = File.read(yaml_file)
      puts EcsCompose::JsonGenerator.new(family, yaml, services: services).json
    end

    desc("up SERVICE [YAML_FILE]",
         "Update an ECS service to match YAML_FILE")
    def up(service, yaml_file="docker-compose.yml")
      yaml = File.read(yaml_file)
      json = EcsCompose::JsonGenerator.new(service, yaml, services: services).json
      EcsCompose::Ecs.update_service_with_json(service, json)
    end

    protected

    # Parse our `services` option.
    def services
      if options[:services]
        options[:services].split(',')
      else
        nil
      end
    end
  end
end
