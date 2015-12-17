module EcsCompose
  # Utilities for comparing ECS task definition JSON, which we need to do
  # to determine whether or not a running service needs to be deployed.
  module Compare
    # :nodoc: An internal table providing a sort order for data types.
    CLASS_ORDINAL = {
      String => 1,
      # These can all be compared against each other.
      Fixnum => 2, Float => 2, Bignum => 2,
      Hash => 3,
      Array => 4,
      FalseClass => 5,
      TrueClass => 6,
      NilClass => 7,
    }

    # Compare two legal JSON values, and do our best to always return a
    # result.
    def self.compare_any(a, b)
      # First sort by type.
      class_order =
        CLASS_ORDINAL.fetch(a.class) <=> CLASS_ORDINAL.fetch(b.class)
      return class_order unless class_order == 0

      # Then sort by value.
      case a
      when Hash
        # Convert the hashes to arrays, sort them to normalize hash key
        # order, and compare them.
        compare_any(a.to_a.sort {|a1, b1| compare_any(a1, b1) },
                    b.to_a.sort {|a1, b1| compare_any(a1, b1) })
      when Array
        # Do a full array comparison so that we can slip in our comparison
        # function.
        for i in 0...([a.length, b.length].max)
          if i >= a.length
            return -1
          elsif i >= b.length
            return 1
          else
            elem_order = compare_any(a[i], b[i])
            return elem_order unless elem_order == 0
          end
        end
        0
      else
        a <=> b
      end
    end

    # Recursively sort all arrays contained in `val`, in order to normalize
    # things like environment variables in different orders.
    def self.sort_recursively(val)
      case val
      when Array
        val.map {|item| sort_recursively(item) }
          .sort {|a1, b1| compare_any(a1, b1) }
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
