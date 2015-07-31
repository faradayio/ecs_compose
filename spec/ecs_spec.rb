require 'spec_helper'

describe EcsCompose::Ecs do
  describe ".update_service_with_json" do
    it "makes the expected AWS calls" do
      # We expect the following `Ecs.run` calls to be made, but we don't
      # actually want to shell out to `awscli` when testing.
      expect(EcsCompose::Ecs).to receive(:run)
        .with("register-task-definition",
              "--cli-input-json", anything) do
        { "taskDefinition" => { "family" => "frontend", "revision" => 2 } }
      end
      expect(EcsCompose::Ecs).to receive(:run)
        .with("update-service", "--service", "my-app",
              "--task-definition", "frontend:2") { {} }

      yaml = <<YAML
app:
  image: "example/app"
  mem_limit: "256m"
YAML

      json = EcsCompose::JsonGenerator.new("frontend", yaml).json
      EcsCompose::Ecs.update_service_with_json("my-app", json)
    end
  end
end
