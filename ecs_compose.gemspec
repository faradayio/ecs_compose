# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ecs_compose/version'

Gem::Specification.new do |spec|
  spec.name          = "ecs_compose"
  spec.version       = EcsCompose::VERSION
  spec.authors       = ["Eric Kidd"]
  spec.email         = ["git@randomhacks.net"]

  spec.summary       = %q{Deploy docker-compose.yml files to Amazon EC2 Container Service}
  spec.description   = %q{An interace to the Amazon EC2 Container Service that works vaguely like docker-compose, for people who are familiar with a docker-compose workflow.}
  spec.homepage      = "https://github.com/faradayio/ecs_compose"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org by setting 'allowed_push_host', or
  # delete this section to allow pushing this gem to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "thor", "~> 0.19.1"
  spec.add_dependency "colorize", "~> 0.7.7"

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec"
end
