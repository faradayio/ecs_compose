require 'psych'

module EcsCompose

  # A collection of multiple task definitions, including names and types.
  class Manifest
    class << self
      # Build a manifest from a single `docker-compose.yml` file, using the
      # supplied type and name.
      def read_from_file(path, project_name, type, name)
        new([TaskDefinition.new(type,
                                compound_name(project_name, name),
                                File.read(path))])
      end

      # Read in a complete manifest.
      def read_from_manifest(path, project_name)
        dir = File.dirname(path)
        yaml = Psych.load_file(path)
        defs = yaml.fetch('task_definitions').map do |name, info|
          TaskDefinition.new(info.fetch('type').to_sym,
                             compound_name(project_name, name),
                             File.read(File.join(dir, info.fetch('path'))))
        end
        new(defs)
      end

      def read_from_cage_export(path, project_name)
        defs = []
        for file in Dir.glob(File.join(path, "*.yml"))
          name = File.basename(file, ".yml")
          defs << TaskDefinition.new(:service,
                                     compound_name(project_name, name),
                                     File.read(file))
        end
        for file in Dir.glob(File.join(path, "tasks/*.yml"))
          name = File.basename(file, ".yml")
          defs << TaskDefinition.new(:task,
                                     compound_name(project_name, name),
                                     File.read(file))
        end
        new(defs)
      end

      private

      # If we've been supplied with a `project_name`, build a compound name.
      def compound_name(project_name, name)
        if project_name.nil?
          name
        else
          "#{project_name}-#{name}"
        end
      end
    end

    attr_reader :task_definitions

    def initialize(task_definitions)
      @task_definitions = task_definitions
    end
  end
end
