module EcsCompose
  module Compare
    def self.sort_recursively!(val)
      case val
      when Array
        val.sort_by! do |item|
          if item.instance_of?(Hash)
            item.to_a.sort
          else 
            item
          end
        end
        val.each {|item| sort_recursively!(item) }
      when Hash
        val.values.each {|item| sort_recursively!(item) }
      end
      val
    end
  end
end
