require 'spec_helper'

describe EcsCompose::ServiceError do
  describe ".fail_if_not_stabilized" do
    subject { EcsCompose::ServiceError.fail_if_not_stabilized(json) }

    context "with stablized containers" do
      let(:json) do
        JSON.parse(<<JSON)
{
  "failures": [],
  "services": []
}
JSON
      end

      it "does nothing" do
        subject
      end
    end

    context "with global failures" do
      let(:json) do
        JSON.parse(<<JSON)
{
  "failures": [{
    "arn": "arn:123",
    "reason": "ERR"
  }],
  "services": []
}
JSON
      end

      it "reports the failures" do
        expect { subject }.to raise_error do |err|
          expect(err.messages) == ["ERR (resource: arn123)"]
        end
      end
    end

    context "with two deployments" do
      let(:json) do
        JSON.parse(<<JSON)
{
  "failures": [],
  "services": [{
    "serviceName": "myapp",
    "deployments": [{}, {}],
    "desiredCount": 1,
    "runningCount": 1
  }]
}
JSON
      end

      it "reports multiple deployments" do
        expect { subject }.to raise_error do |err|
          expect(err.messages) ==
            ["myapp: multiple versions still deployed (see AWS console for details)"]
        end
      end
    end

    context "with desired count != running count" do
      let(:json) do
        JSON.parse(<<JSON)
{
  "failures": [],
  "services": [{
    "serviceName": "myapp",
    "deployments": [{}],
    "desiredCount": 2,
    "runningCount": 1
  }]
}
JSON
      end

      it "reports that not all containers are running" do
        expect { subject }.to raise_error do |err|
          expect(err.messages) ==
            ["myapp: 2 instances desired, 1 running (see AWS console for details)"]
        end
      end
    end
  end
end
