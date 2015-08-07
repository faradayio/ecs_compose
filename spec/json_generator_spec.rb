require 'spec_helper'

describe EcsCompose::JsonGenerator do
  subject do
    EcsCompose::JsonGenerator.new("my-app", yaml).generate()
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
    - "3001:3000"
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
      expect(app["links"]).to eq(["service1", "service2:db"])
      expect(app["portMappings"])
        .to eq([{ "hostPort" => 80, "containerPort" => 80 },
                { "hostPort" => 3001, "containerPort" => 3000 }])
      expect(app["essential"]).to eq(true)
      expect(app["entryPoint"]).to eq(["/app/runner", "-d"])
      expect(app["command"]).to eq(["bundle", "exec", "bar"])
      expect(app["environment"])
        .to eq([{ "name" => "SPEED", "value" => "1" }])
      expect(app["mountPoints"]).to eq([])
      expect(app["volumesFrom"]).to eq([])

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
end

