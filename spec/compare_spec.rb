require 'spec_helper'
require 'json'

describe EcsCompose::Compare do
  describe ".compare_any" do
    it "permits comparison of any type which may appear in JSON" do
      # According to http://www.json.org/, valid JSON types are: string
      # number object array true false nil.  This list should be a set of
      # legal JSON values sorted from smallest to largest.
      values = ["a", "b", 1, 1.5, 2,
                {"a" => 1}, {"a" => 2}, {"b" => 1},
                {"d" => 2, "c" => 1}, {"d" => 1, "c" => 2},
                {"e" => 1}, {"e" => nil},
                [], [1], [1,1], [1,2], [2], [2,1], [nil], false, true, nil]
      for i in 0...values.length
        for j in 0...values.length
          puts "#{values[i].inspect} <=> #{values[j].inspect}"
          expect(EcsCompose::Compare.compare_any(values[i], values[j]))
            .to eq((i-j) <=> 0)
        end
      end
    end
  end

  describe ".sort_recursively!" do
    it "sorts lists recursively, including lists of hashes" do
      data = {"a" => [{"b" => [2]}, {"b" => [1]}]}
      sorted = EcsCompose::Compare.sort_recursively(data)
      expect(sorted).to eq({"a" => [{"b" => [1]}, {"b" => [2]}]})
      # Ensure no mutation.
      expect(data).to eq({"a" => [{"b" => [2]}, {"b" => [1]}]})
    end

    it 'sorts arrays of arrays', :focus do
      data = [[[],[]], [3,4], [1,2], [5, 6]]
      sorted = EcsCompose::Compare.sort_recursively(data)
      expect(sorted).to eq([[1,2], [3,4], [5, 6], [[],[]]])
    end
  end

  describe ".task_definitions_match?" do
    before do
      allow(ENV).to receive(:has_key?).with('VAULT_ADDR') { true }
      allow(ENV).to receive(:fetch).with('VAULT_ADDR') { '' }
      allow(ENV).to receive(:has_key?).with('VAULT_MASTER_TOKEN') { true }
      allow(ENV).to receive(:fetch).with('VAULT_MASTER_TOKEN') { '' }
    end

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
