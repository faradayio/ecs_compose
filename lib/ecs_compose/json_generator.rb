require 'digest/sha1'
require 'json'
require 'psych'

module EcsCompose
  class ContainerKeyError < KeyError
  end

  # Converts from raw YAML text in docker-compose.yml format to ECS task
  # definition JSON.
  class JsonGenerator

    # Create a new generator, specifying the family name to use, and the
    # raw YAML input.
    def initialize(family, yaml_text)
      @family = family
      @yaml = Psych.load(yaml_text)
    end

    # Generate an ECS task definition as a raw Ruby hash.
    def generate
      # Generate JSON for our containers.
      containers = @yaml.map do |name, fields|
        # Skip this service if we've been given a list to emit, and
        # this service isn't on the list.
        begin
          mount_points = (fields["volumes"] || []).map do |v|
            host, container, ro = v.split(':')
            {
              "sourceVolume" => path_to_vol_name(host),
              "containerPath" => container,
              "readOnly" => (ro == "ro")
            }
          end

          json = {
            "name" => name,
            "image" => fields.fetch("image"),
            # Default to a tiny guaranteed CPU share.  Currently, 2 is the
            # smallest meaningful value, and various ECS tools will round
            # smaller numbers up.
            "cpu" => fields["cpu_shares"] || 2,
            "memory" => mem_limit_to_mb(fields.fetch("mem_limit")),
            "links" => fields["links"] || [],
            "portMappings" =>
              (fields["ports"] || []).map {|pm| port_mapping(pm) },
            "essential" => true,
            "environment" => environment(fields["environment"] || {}),
            "mountPoints" => mount_points,
            "volumesFrom" => [],
          }
          if fields.has_key?("entrypoint")
            json["entryPoint"] = command_line(fields.fetch("entrypoint"))
          end
          if fields.has_key?("command")
            json["command"] = command_line(fields.fetch("command"))
          end
          json

        rescue KeyError => e
          # This makes it a lot easier to localize errors a bit.
          raise ContainerKeyError.new("#{e.message} processing container \"#{name}\"")
        end
      end

      # Generate our top-level volume declarations.
      volumes = @yaml.map do |name, fields|
        (fields["volumes"] || []).map {|v| v.split(':')[0] }
      end.flatten.sort.uniq.map do |host_path|
        {
          "name" => path_to_vol_name(host_path),
          "host" => { "sourcePath" => host_path }
        }
      end

      # Return our final JSON.
      {
        "family" => @family,
        "containerDefinitions" => containers,
        "volumes" => volumes
      }
    end

    # Generate an ECS task definition as serialized JSON.
    def json
      # We do not want to insert much extra whitespace, because ECS imposes
      # a maximum file-size limit based on bytes.
      JSON.generate(generate())
    end

    # Generate an `--overrides` value for use with with `aws ecs run-task`
    # as a raw Ruby hash.
    def generate_override(environment: {}, entrypoint: nil, command: nil)
      # Right now, we only support overriding for single-container tasks, so
      # find our single container if we have it.
      if @yaml.length != 1
        raise "Can only override task attributes for single-container tasks"
      end
      name = @yaml.keys.first
      container_overrides = { "name" => name }

      # Apply any environment overrides.
      if environment && !environment.empty?
        container_overrides["environment"] = environment.map do |k, v|
          { "name" => k, "value" => v }
        end
      end

      # Apply any other overrides.
      container_overrides["command"] = command if command
      # TODO: This may not actually be supported by AWS yet.
      container_overrides["entryPoint"] = entrypoint if entrypoint

      # Return nil if we haven't generated any actual overrides.
      if container_overrides.length > 1
        { "containerOverrides" => [ container_overrides ] }
      else
        nil
      end
    end

    # Like generate, but return serialized JSON.
    def generate_override_json(**args)
      JSON.generate(generate_override(**args))
    end

    protected

    # Parse a Docker-style `mem_limit` and convert to megabytes.
    def mem_limit_to_mb(mem_limit)
      unless mem_limit.downcase =~ /\A(\d+)([bkmg])\z/
        raise "Cannot parse docker memory limit: #{mem_limit}"
      end
      val = $1.to_i
      case $2
      when "b" then (val / (1024.0 * 1024.0)).ceil
      when "k" then (val / 1024.0).ceil
      when "m" then (val * 1.0).ceil
      when "g" then (val * 1024.0).ceil
      else raise "Can't convert #{mem_limit} to megabytes"
      end
    end

    # Parse a Docker-style port mapping and convert to ECS format.
    def port_mapping(port)
      case port.to_s
      when /\A(\d+)\z/
        port = $1.to_i
        { "hostPort" => port, "containerPort" => port }
      when /\A(\d+):(\d+)\z/ 
        { "hostPort" => $1.to_i, "containerPort" => $2.to_i }
      else
        raise "Cannot parse port specification: #{port}"
      end
    end

    # Convert a command-line to an array of individual arguments.
    #
    # TODO: What is the exact format of the docker-compose fields here?
    # Can the user pass an array?  Is there a way to escape spaces?
    def command_line(input)
      input.split(/ /)
    end

    # Convert a docker-compose environment to ECS format.  There are other
    # possible formats for this that we don't support yet.
    def environment(env)
      # We need to force string values to keep ECS happy.
      env.map {|k, v| { "name" => k, "value" => v.to_s } }
    end

    # Convert a Unix path into a valid volume name.
    def path_to_vol_name(path)
      # Ensure (extremely high probability of) uniqueness by hashing the
      # pathname, and then include a simplified version of the path for
      # readability.  This might fail, but the odds are the same as a
      # failure of git's content-based addressing.
      Digest::SHA1.hexdigest(path) + path.gsub(/[\/.]/, '_')
    end
  end
end
