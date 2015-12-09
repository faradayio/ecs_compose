require 'spec_helper'
require 'json'

describe EcsCompose::Compare do
  describe ".sort_recursively!" do
    it "sorts lists recursively, including lists of hashes" do
      data = {a: [{b:[2]}, {b:[1]}]}
      sorted = EcsCompose::Compare.sort_recursively(data)
      expect(data).to eq({a: [{b:[2]}, {b:[1]}]})
      expect(sorted).to eq({a: [{b:[1]}, {b:[2]}]})
    end
  end

  describe ".task_definitions_match?" do
    def load_taskdef(id)
      JSON.parse(File.read(fixture_path("taskdef#{id}.json")))
        .fetch("taskDefinition")
    end

    let(:taskdef14) { load_taskdef(14) }
    let(:taskdef15) { load_taskdef(15) }

    it "normalizes ARNs and list orders" do
      result = EcsCompose::Compare.task_definitions_match?(taskdef14, taskdef15)
      expect(result).to eq(true)
    end
  end
end
