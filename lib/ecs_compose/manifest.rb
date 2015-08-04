require 'psych'

module EcsCompose

  # A collection of multiple task definitions, including names and types.
  class Manifest
    # Build a manifest from a single `docker-compose.yml` file, using the
    # supplied type and name.
    def self.read_from_file(path, type, name)
      new([TaskDefinition.new(type, name, File.read(path))])
    end

    # Read in a complete manifest.
    def self.read_from_manifest(path)
      dir = File.dirname(path)
      defs = Psych.load_file(path)['task_definitions'].map do |name, info|
        TaskDefinition.new(info['type'].to_sym,
                           name,
                           File.read(File.join(dir, info['path'])))
      end
      new(defs)
    end

    attr_reader :task_definitions

    def initialize(task_definitions)
      @task_definitions = task_definitions
    end
  end
end
