module EcsCompose
  # Utilities for comparing ECS task definition JSON, which we need to do
  # to determine whether or not a running service needs to be deployed.
  module Compare

    # Recursively sort all arrays contained in `val`, in order to normalize
    # things like environment variables in different orders.
    def self.sort_recursively(val)
      case val
      when Array
        val.sort_by do |item|
          if item.instance_of?(Hash)
            item.to_a.sort
          elsif item.instance_of?(Array)
            # for an array of arrays, just return 1
            1
          else 
            item
          end
        end.map {|item| sort_recursively(item) }
      when Hash
        newval = {}
        val.each do |k, v|
          newval[k] = sort_recursively(v)
        end
        newval
      else
        val
      end
    end

    # Do two task definitions match after normalization?
    def self.task_definitions_match?(td1, td2)
      normalize_task_definition(td1) == normalize_task_definition(td2)
    end

    protected

    # Sort and strip out things we expect to change.
    def self.normalize_task_definition(td)
      td = sort_recursively(td)
      td.delete("taskDefinitionArn")
      td.delete("revision")
      Plugins.plugins.each {|p| p.normalize_task_definition!(td) }
      td
    end
  end
end
