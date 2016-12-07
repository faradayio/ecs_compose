# DEVELOPMENT ONLY. This is used by go-publish.sh to build our
# ecs_compose gem.

FROM ruby:2.3.3

WORKDIR /gem

# Allow docker to cache the gem downloads even if unreleated files change.
ADD Gemfile /gem/
ADD ecs_compose.gemspec /gem/
ADD lib/ecs_compose/version.rb /gem/lib/ecs_compose/
RUN bundle install

# Add the rest of the files.
ADD . /gem/

# Command to test and publish the gem.
CMD /gem/publish.sh
