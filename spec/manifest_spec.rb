require 'spec_helper'

describe EcsCompose::Manifest do

  describe ".read_from_file" do
    let(:file) { fixture_path("deploy/hello.yml") }

    subject { EcsCompose::Manifest.read_from_file(file, :service, 'hello') }

    it "loads a single task definition with the supplied type and name" do
      defs = subject.task_definitions
      expect(defs.length).to eq(1)
      expect(defs[0].type).to eq(:service)
      expect(defs[0].name).to eq('hello')
      expect(defs[0].yaml).to eq(File.read(file))
    end
  end

  describe ".read_from_manifest" do
    let(:manifest) { fixture_path("deploy/DEPLOY-MANIFEST.yml") }

    subject { EcsCompose::Manifest.read_from_manifest(manifest) }

    it "loads all task definitions from the manifest" do
      defs = subject.task_definitions
      expect(defs.length).to eq(2)

      hello = defs[0]
      expect(hello.type).to eq(:service)
      expect(hello.name).to eq('hello')
      expect(hello.yaml).to eq(File.read(fixture_path("deploy/hello.yml")))

      hellocli = defs[1]
      expect(hellocli.type).to eq(:task)
      expect(hellocli.name).to eq('hellocli')
      expect(hellocli.yaml).to eq(File.read(fixture_path("deploy/hellocli.yml")))
    end
  end
end
