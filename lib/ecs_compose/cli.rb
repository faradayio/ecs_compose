require "ecs_compose"
require "thor"

module EcsCompose
  # Our basic command-line interface.
  class CLI < Thor
    DEFAULT_FILE = "docker-compose.yml"
    DEFAULT_MANIFEST = "deploy/DEPLOY-MANIFEST.yml"

    class_option(:manifest, type: :string,
                 aliases: %w(-m),
                 desc: "Manifest describing a set of tasks and services (takes precedence over --file) [default: #{DEFAULT_MANIFEST}]")
    class_option(:file, type: :string,
                 aliases: %w(-f),
                 desc: "File describing a single task or service [default: #{DEFAULT_FILE}]")
    class_option(:file_info, type: :string,
                 aliases: %w(-i),
                 desc: "Type and name for use with --file [ex: 'service:hello' or 'task:migrate']")

    desc("up [SERVICES...]", "Register ECS task definitions and update services")
    def up(*services)
      available = manifest.task_definitions.select {|td| td.type == :service }
      chosen = all_or_specified(available, services)

      chosen.each do |service|
        json = EcsCompose::JsonGenerator.new(service.name, service.yaml).json
        EcsCompose::Ecs.update_service_with_json(service.name, json)
      end
    end

    desc("register [TASK_DEFINITIONS...]", "Register ECS task definitions")
    def register(*task_definitions)
      available = manifest.task_definitions
      chosen = all_or_specified(available, task_definitions)

      chosen.each do |td|
        json = EcsCompose::JsonGenerator.new(td.name, td.yaml).json
        EcsCompose::Ecs.register_task_definition(json)
      end
    end

    desc("json [TASK_DEFINITION]",
         "Convert a task definition to ECS JSON format")
    def json(task_definition=nil)
      if task_definition.nil?
        choices = manifest.task_definitions.map {|td| td.name }
        case choices.length
        when 0
          fatal_err("Please supply a manifest with at least one task definition")
        when 1
          task_definition = choices.first
        else
          fatal_err("Please choose one of: #{choices.join(', ')}")
        end
      end

      found = manifest.task_definitions.find {|td| td.name } or
        fatal_err("Can't find task definition: #{task_definition}")
      puts EcsCompose::JsonGenerator.new(found.name, found.yaml).json
    end

    protected

    # Choose either all items in `available`, or just those with the
    # specified `names`.
    def all_or_specified(available, names)
      if names.empty?
        available
      else
        available.select {|td| names.include?(td.name) }
      end      
    end

    # Figure out whether we have a manifest or a docker-compose.yml.  We
    # check supplied flags first, then defaults, and we prefer manifests
    # when there's a tie.
    def mode
      @mode ||=
        if options.manifest
          :manifest
        elsif options.file
          :file
        elsif File.exist?(DEFAULT_MANIFEST)
          :manifest
        elsif File.exist?(DEFAULT_FILE)
          :file
        else
          fatal_err("Unable to find either #{DEFAULT_FILE} or #{DEFAULT_MANIFEST}")
        end
    end

    # Create a manifest, either by reading it in, or synthesizing it from a
    # `docker-compose.yml` file and some extra arguments.
    def manifest
      @manifest ||=
        case mode
        when :manifest
          Manifest.read_from_manifest(options.manifest || DEFAULT_MANIFEST)
        when :file
          info = options.file_info
          if info.nil?
            fatal_err("Must pass -i option when using docker-compose.yml")
          end
          unless info =~ /\A(service|task):[-_A-Za-z0-9\z]/
            fatal_err("Incorrectly formatted -i option")
          end
          Manifest.read_from_file(options.file || DEFAULT_FILE,
                                  type.to_sym, name)
        else raise "Unknown mode: #{mode}"
        end
    end

    # Print an error and quit.
    def fatal_err(msg)
      STDERR.puts(msg.red)
      exit(1)
    end
  end
end
