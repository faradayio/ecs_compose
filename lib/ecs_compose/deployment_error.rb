module EcsCompose
  # Common superclass of TaskError and ServiceError.
  class DeploymentError < RuntimeError
    #:nodoc:
    def self.failure_error(failure)
      "#{failure.fetch("reason")} (resource: #{failure.fetch("arn")})"
    end

    attr_reader :messages

    # Create a new task error with one or more messages.
    def initialize(messages)
      message = (["ECS deployment errors occurred:"] + messages).join("\n- ")
      super(message)
      @messages = messages
    end
  end
end
