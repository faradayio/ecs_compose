module EcsCompose
  class Cluster
    attr_reader :name

    def initialize(name)
      @name = name
    end
  end
end
