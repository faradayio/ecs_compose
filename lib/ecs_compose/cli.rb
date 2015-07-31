require "ecs_compose"
require "thor"

module EcsCompose
  class Cli < Thor
    desc("conv FAMILY [YAML_FILE]",
         "Convert docker-compose.yml to ECS JSON format")
    def jsonify(family, yaml_file="docker-compose.yml")
      yaml = File.read(yaml_file)
      puts EcsCompose::JsonGenerator.new(family, yaml).json
    end
  end
end
