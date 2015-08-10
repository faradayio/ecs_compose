require 'spec_helper'

describe EcsCompose::TaskError do

  describe ".fail_on_errors" do
    subject { EcsCompose::TaskError.fail_on_errors(json) }

    context "with no errors" do
      let(:json) do
        JSON.parse(<<JSON)
{
  "failures": [],
  "tasks": [{
    "containers": [{ "name": "cucumber", "exitCode": 0 }]
  }]
}
JSON
      end

      it "does nothing" do
        subject
      end
    end

    context "with a failure and a container error" do
      let(:json) do
        JSON.parse(<<'JSON')
{
  "failures": [{
    "arn": "arn:123",
    "reason": "ERR"
  }],
  "tasks": [{
    "taskArn": "arn:aws:ecs:us-east-1:1234567890:task/12692eab-3774-4ec4-a76c-1a4a987b17de", 
    "containers": [{
      "containerArn": "arn:aws:ecs:us-east-1:1234567890:container/071d03ed-5853-471d-b91a-41c81e7cdd3c", 
      "taskArn": "arn:aws:ecs:us-east-1:1234567890:task/12692eab-3774-4ec4-a76c-1a4a987b17de", 
      "name": "cucumber",
      "lastStatus": "STOPPED",
      "reason": "DockerStateError: [8] System error: exec: \"--sdfjasldgj\": executable file not found in $PATH", 
      "exitCode": -1
    }]
  }]
}
JSON
      end

      it "reports failures and container errors" do
        expect { subject }.to(raise_error do |err|
          expect(err.messages).to eq([
            "ERR (resource: arn:123)",
            "cucumber: DockerStateError: [8] System error: exec: \"--sdfjasldgj\": executable file not found in $PATH"
          ])
        end)
      end
    end
  end

  describe ".container_error" do
    it "returns nil if the exit code was 0" do
      container = { "name" => "cucumber", "exitCode" => 0 }
      expect(EcsCompose::TaskError.container_error(container)).to eq(nil)
    end

    it "returns the `reason` field if present" do
      container = { "name" => "cucumber", "exitCode" => -1, "reason" => "ERR" }
      expect(EcsCompose::TaskError.container_error(container))
        .to eq("cucumber: ERR")
    end

    it "returns a generic error if the `reason` field is absent" do
      container = { "name" => "cucumber", "exitCode" => -1 }
      expect(EcsCompose::TaskError.container_error(container))
        .to eq("cucumber: exited with code -1")
    end
  end

  describe ".failure_error" do
    it "returns the reason for the failure" do
      failure = { "arn" => "arn:123", "reason" => "ERR" }
      expect(EcsCompose::TaskError.failure_error(failure))
        .to eq("ERR (resource: arn:123)")
    end
  end
end
