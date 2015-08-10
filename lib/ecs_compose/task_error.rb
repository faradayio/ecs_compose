module EcsCompose
  # We raise this error if `aws ecs describe-tasks` indicates that a
  # process has failed.
  class TaskError < RuntimeError
    def self.fail_on_errors(task_descriptions)
      errs1 = task_descriptions.fetch("failures").map {|f| failure_error(f) }
      errs2 = task_descriptions.fetch("tasks").map do |task|
        task.fetch("containers").map do |container|
          container_error(container)
        end
      end.flatten.compact
      errs = errs1 + errs2
      unless errs.empty?
        raise new(errs)
      end
    end

    #:nodoc:
    def self.container_error(container)
      exit_code = container.fetch("exitCode")
      name = container.fetch("name")
      if exit_code == 0
        nil
      elsif container.has_key?("reason")
        "#{name}: #{container.fetch("reason")}"
      else
        "#{name}: exited with code #{exit_code}"
      end
    end

    #:nodoc:
    def self.failure_error(failure)
      "#{failure.fetch("reason")} (resource: #{failure.fetch("arn")})"
    end

    attr_reader :messages

    # Create a new task error with one or more messages.
    def initialize(messages)
      message = (["Errors running tasks:"] + messages).join("\n- ")
      super(message)
      @messages = messages
    end
  end
end
