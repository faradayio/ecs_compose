require "ecs_compose"
require "thor"

module EcsCompose
  # Our basic command-line interface.
  class CLI < Thor
    desc("conv FAMILY [YAML_FILE]",
         "Convert docker-compose.yml to ECS JSON format")
    def jsonify(family, yaml_file="docker-compose.yml")
      yaml = File.read(yaml_file)
      puts EcsCompose::JsonGenerator.new(family, yaml).json
    end

    desc("up SERVICE [YAML_FILE]",
         "Update an ECS service to match YAML_FILE")
    def up(service, yaml_file="docker-compose.yml")
      yaml = File.read(yaml_file)
      json = EcsCompose::JsonGenerator.new(service, yaml).json
      EcsCompose::Ecs.update_service_with_json(service, json)
    end
  end
end
