require 'spec_helper'

describe EcsCompose::TaskDefinition do
  let(:cluster) { EcsCompose::Cluster.new("default") }
  let(:yaml) { File.read(fixture_path(yaml_path)) }

  context "for a service" do
    let(:yaml_path) { "deploy/hello.yml" }
    subject { EcsCompose::TaskDefinition.new(:service, "hello", yaml) }

    it "has the attributes that were passed to the constructor" do
      expect(subject.type).to eq(:service)
      expect(subject.name).to eq("hello")
      expect(subject.yaml).to eq(yaml)
    end

    it "can be converted to ECS JSON format" do
      expect(JSON.parse(subject.to_json)['family']).to eq('hello')
    end

    describe "#register" do
      it "registers the task definition with ECS" do
        expect(EcsCompose::Ecs).to receive(:run)
          .with("describe-task-definition", "--task-definition", "hello") do
          { "taskDefinition" => { "family" => "hello", "revision" => 1 } }
        end
        expect(EcsCompose::Ecs).to receive(:run)
          .with("register-task-definition", "--cli-input-json", anything) do
          { "taskDefinition" => { "family" => "hello", "revision" => 2 } }
        end
        subject.register
      end
    end

    describe "#update" do
      it "registers the task definition with ECS and updates the service" do
        expect(EcsCompose::Ecs).to receive(:run)
          .with("describe-task-definition", "--task-definition", "hello") do
          { "taskDefinition" =>
            { "family" => "hello", "revision" => 1, "dummy" => "foo" } }
        end
        expect(EcsCompose::Ecs).to receive(:run)
          .with("register-task-definition",
                "--cli-input-json", anything) do
          { "taskDefinition" => { "family" => "hello", "revision" => 2 } }
        end
        expect(EcsCompose::Ecs).to receive(:run)
          .with("update-service",
                "--cluster", "default",
                "--service", "hello",
                "--task-definition", "hello:2") { {} }
        expect(EcsCompose::Ecs).to receive(:run)
          .with("wait", "services-stable",
                "--cluster", "default",
                "--services", "hello")
        expect(EcsCompose::Ecs).to receive(:run)
          .with("describe-services",
                "--cluster", "default",
                "--services", "hello") do
          # We may need to fill in more of these fields later.
          { "failures" => [], "services" => [] }
        end

        service = subject.update(cluster)
        expect(service).to eq("hello")
        EcsCompose::TaskDefinition.wait_for_services(cluster, [service])
      end
    end

    describe "#scale" do
      it "updates the desired count for the service" do
        expect(EcsCompose::Ecs).to receive(:run)
          .with("update-service",
                "--cluster", "default",
                "--service", "hello",
                "--desired-count", "3") { {} }
        service = subject.scale(cluster, 3)
        expect(service).to eq("hello")
      end
    end
  end

  context "for a task" do
    let(:yaml_path) { "deploy/hellocli.yml" }
    subject { EcsCompose::TaskDefinition.new(:task, "hellocli", yaml) }

    describe "#run" do
      it "registers the task definition with ECS and runs the task" do
        expect(EcsCompose::Ecs).to receive(:run)
          .with("describe-task-definition", "--task-definition", "hellocli") do
          { "taskDefinition" =>
            { "family" => "hellocli", "revision" => 0, "dummy" => "foo" } }
        end
        expect(EcsCompose::Ecs).to receive(:run)
          .with("register-task-definition",
                "--cli-input-json", anything) do
          { "taskDefinition" => { "family" => "hellocli", "revision" => 1 } }
        end
        expect(EcsCompose::Ecs).to receive(:run)
          .with("run-task",
                "--cluster", "default",
                "--task-definition", "hellocli:1",
                "--overrides", anything,
                "--started-by", "test") do
          { "tasks" => [{ "taskArn" => "arn:123" }] }
        end
        expect(EcsCompose::Ecs).to receive(:run)
          .with("wait", "tasks-stopped",
                "--cluster", "default",
                "--tasks", "arn:123")
        expect(EcsCompose::Ecs).to receive(:run)
          .with("describe-tasks",
                "--cluster", "default",
                "--tasks", "arn:123") do
          # We may need to fill in more of these fields later.
          { "failures" => [], "tasks" => [] }
        end

        arn = subject.run(cluster,
                          started_by: "test",
                          command: ["/bin/bash"])
        expect(arn).to eq("arn:123")
        EcsCompose::TaskDefinition.wait_for_tasks(cluster, [arn])
      end
    end
  end
end
