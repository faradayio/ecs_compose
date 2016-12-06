$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'ecs_compose'

load File.expand_path('../support/stub.rb', __FILE__)

def fixture_path(relpath)
  File.join(File.dirname(__FILE__), "fixtures", relpath)
end
