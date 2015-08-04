module EcsCompose

  # Information required to create an ECS task definition.
  class TaskDefinition
    attr_reader :type, :name, :yaml

    def initialize(type, name, yaml)
      @name = name
      @type = type
      @yaml = yaml
    end
  end
end
