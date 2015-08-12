require 'spec_helper'

describe EcsCompose::Cluster do
  it "has a name" do
    cluster = EcsCompose::Cluster.new('production')
    expect(cluster.name).to eq('production')
  end
end
