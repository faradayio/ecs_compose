require 'spec_helper'

describe EcsCompose::Compare do
  describe ".sort_recursively!" do
    it "sorts lists recursively, including lists of hashes" do
      data = {a: [{b:[2]}, {b:[1]}]}
      EcsCompose::Compare.sort_recursively!(data)
      expect(data).to eq({a: [{b:[1]}, {b:[2]}]})
    end
  end
end
