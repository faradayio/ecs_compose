# EcsCompose

**This is a work in progress!**

This gem attempts to provide a `docker-compose`-like interface to Amazon EC2 Container Service (ECS).  It takes a `docker-compose.yml` file, and uses the included container definitions to update an ECS task definition and an ECS service.

This is still somewhat rudimentary, and the command-line interface is subject to change.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'ecs_compose'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install ecs_compose

## Usage

Using the Amazon Web Services console, create a new ECS cluster and define a service `my-service`.  Describe your service using a standard `docker-compose.yml` file.  Then run:

```sh
ecs-compose -i service:my-service up
```

This will update the task definition `my-service`, and then update the running copy of `my-service` to the new task definition.  The `-i` argument specifies the ECS task type (a one-shot `task`, or a persistent `service`, as well as a value to use as the task definiton name and family name on ECS.

There's also a "manifest" mode that allows you to work with multiple
`docker-compose.yml` files, each defining a different service or task.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment. Run `bundle exec ecs_compose` to use the gem in this directory, ignoring other installed copies of this gem.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/ecs_compose.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

