require 'spec_helper'

describe EcsCompose::JsonGenerator do
  subject do
    EcsCompose::JsonGenerator.new("my-app", yaml).generate()
  end

  context "with a version 2 file (limited support)" do
    let(:yaml) do
      <<YAML
---
version: "2"
services:
  logspout:
    image: gliderlabs/logspout
    mem_limit: 16m
YAML
    end

    it "generates the appropriate JSON" do
      expect(subject["family"]).to eq("my-app")
      expect(subject["volumes"]).to eq([])

      containers = subject["containerDefinitions"].sort_by {|c| c["name"] }
      expect(containers.map {|c| c["name"] }).to eq(["logspout"])

      logspout = containers[0]
      expect(logspout["memory"]).to eq(16)
      expect(logspout["image"]).to eq("gliderlabs/logspout")
    end
  end

  context "using all supported YAML features" do
    let(:yaml) do
      <<YAML
---
# Some of these fields we use, others we ignore because they're not supported
# in the ECS JSON format.
app:
  image: "example/foo:19"
  build: "foo"
  dockerfile: "Dockerfile2"
  command: "bundle exec bar"
  links:
    - "service1"
    - "service2:db"
  extra_hosts:
    - "cache:192.168.0.10"
  ports:
    - "80"
    - "53/udp"
    - "3001:3000"
    - "1000:1000/udp"
  expose:
    - "8000"
  environment:
    SPEED: 1
  labels:
    version: "19"
  working_dir: "/app"
  entrypoint: "/app/runner -d"
  user: "app"
  hostname: "app"
  domainname: "example.com"
  mem_limit: "512m"
  privileged: true
  restart: always
  stdin_open: true
  tty: true
  cpu_shares: 512
  cpuset: 0-3,5
  read_only: true
  ulimits:
    nproc: 65535
    nofile:
      soft: 20000
      hard: 40000

service1:
  image: "example/service1"
  restart: "on-failure:3"
  mem_limit: "1G"

service2:
  image: "example/service2"
  mem_limit: "100b"
YAML

      # We definitely don't support these yet.
      #external_links
      #volumes
      #volumes_from
      #env_file
      #extends
      #log driver
      #net
      #pid
      #dns
      #cap_add, cap_drop
      #dns_search
      #devices
      #security_opt
    end

    it "generates the equivalent ECS JSON" do
      expect(subject["family"]).to eq("my-app")
      expect(subject["volumes"]).to eq([])

      containers = subject["containerDefinitions"].sort_by {|c| c["name"] }
      expect(containers.map {|c| c["name"] })
        .to eq(["app", "service1", "service2"])

      app = containers[0]
      expect(app["image"]).to eq("example/foo:19")
      expect(app["cpu"]).to eq(512)
      expect(app["memory"]).to eq(512)
      expect(app["privileged"]).to eq(true)
      expect(app["links"]).to eq(["service1", "service2:db"])
      expect(app["portMappings"])
        .to eq([{ "hostPort" => 80, "containerPort" => 80, "protocol" => "tcp" },
                { "hostPort" => 53, "containerPort" => 53, "protocol" => "udp" },
                { "hostPort" => 3001, "containerPort" => 3000, "protocol" => "tcp" },
                { "hostPort" => 1000, "containerPort" => 1000, "protocol" => "udp" }])
      expect(app["essential"]).to eq(true)
      expect(app["entryPoint"]).to eq(["/app/runner", "-d"])
      expect(app["command"]).to eq(["bundle", "exec", "bar"])
      expect(app["environment"])
        .to eq([{ "name" => "SPEED", "value" => "1" }])
      expect(app["mountPoints"]).to eq([])
      expect(app["volumesFrom"]).to eq([])
      expect(app["ulimits"]).to eq([
        { "name" => "nproc", "softLimit" => 65535, "hardLimit" => 65535 },
        { "name" => "nofile", "softLimit" => 20000, "hardLimit" => 40000 },
      ])

      service1 = containers[1]
      expect(service1["image"]).to eq("example/service1")
      expect(service1["memory"]).to eq(1024)
      expect(service1["essential"]).to eq(true)

      service2 = containers[2]
      expect(service2["image"]).to eq("example/service2")
      expect(service2["memory"]).to eq(1)
      expect(service2["essential"]).to eq(true)
    end
  end

  context "using a Docker volume" do
    VOL_NAME = "ea6c68e6d15cfad87656d889a13b56377d13e174_var_run_docker_sock"

    let(:yaml) do
      <<EOD
logspout:
  type: backend
  image: gliderlabs/logspout
  volumes:
    - /var/run/docker.sock:/tmp/docker.sock
  command: "syslog://logs.papertrailapp.com:123456"
  mem_limit: 16m # staging: 6m production: 9m
EOD
    end

    it "lists the volume at the top level" do
      vols = subject["volumes"]
      expect(vols.length).to eq(1)
      expect(vols[0]["name"]).to eq(VOL_NAME)
      expect(vols[0]["host"]["sourcePath"]).to eq("/var/run/docker.sock")
    end

    it "mounts the volume in the appropriate container" do
      mounts = subject["containerDefinitions"][0]["mountPoints"]
      expect(mounts.length).to eq(1)
      expect(mounts[0]["sourceVolume"]).to eq(VOL_NAME)
      expect(mounts[0]["containerPath"]).to eq("/tmp/docker.sock")
      expect(mounts[0]["readOnly"]).to eq(false)
    end
  end

  describe "#generate_override" do
    let(:yaml) { File.read(fixture_path("deploy/hellocli.yml")) }
    subject { EcsCompose::JsonGenerator.new('hellocli', yaml) }

    it "returns nil if no overrides are applied" do
      expect(subject.generate_override()).to eq(nil)
    end

    it "allows overriding environment variables" do
      override = subject.generate_override(environment: { "FOO" => "BAR" })
      containerOverrides = override.fetch('containerOverrides')
      expect(containerOverrides.length).to eq(1)
      expect(containerOverrides[0].fetch("environment"))
        .to eq([{ "name" => "FOO", "value" => "BAR" }])
    end

    it "allows overriding the container's command" do
      override = subject.generate_override(command: ["sudo", "shutdown"])
      containerOverrides = override.fetch('containerOverrides')
      expect(containerOverrides.length).to eq(1)
      expect(containerOverrides[0].fetch("command"))
        .to eq(["sudo", "shutdown"])
    end

    it "allows overriding the container's entrypoint" do
      override = subject.generate_override(entrypoint: ["/usr/bin/fish"])
      containerOverrides = override.fetch('containerOverrides')
      expect(containerOverrides.length).to eq(1)
      expect(containerOverrides[0].fetch("entryPoint"))
        .to eq(["/usr/bin/fish"])
    end
  end
end
