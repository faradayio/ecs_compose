# coding: utf-8
Gem::Specification.new do |spec|
  spec.name          = "ecs-compose"
  spec.version       = '0.0.0'
  spec.authors       = ["Eric Kidd"]
  spec.email         = ["git@randomhacks.net"]

  spec.summary       = %q{ALIAS FOR ecs_compose. Deploy docker-compose.yml files to Amazon EC2 Container Service}
  spec.description   = %q{ALIAS FOR ecs_compose. An interace to the Amazon EC2 Container Service that works vaguely like docker-compose, for people who are familiar with a docker-compose workflow.}
  spec.homepage      = "https://github.com/faradayio/ecs_compose"
  spec.license       = "MIT"

  spec.files         = ['ecs-compose.gemspec']

  spec.add_runtime_dependency 'ecs_compose'
end
