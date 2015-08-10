module EcsCompose
  # We raise this error if `aws ecs describe-services` indicates that a
  # service has failed to stablize.
  class ServiceError < DeploymentError
    # Raise an error if any of the described services failed to stabilize.
    def self.fail_if_not_stabilized(service_descriptions)
      failures = service_descriptions.fetch("failures")
      services = service_descriptions.fetch("services")

      errs1 = failures.map {|f| failure_error(f) }

      errs2 = services.select do |s|
        s.fetch("deployments").length != 1
      end.map do |s|
        "#{s.fetch("serviceName")}: multiple versions still deployed (see AWS console for details)"
      end

      errs3 = services.select do |s|
        s.fetch("desiredCount") != s.fetch("runningCount")
      end.map do |s|
        "#{s.fetch("serviceName")}: #{s.fetch("desiredCount")} instances desired, #{s.fetch("runningCount")} running (see AWS console for details)"
      end

      errs = errs1 + errs2 + errs3
      unless errs.empty?
        raise new(errs)
      end
    end
  end
end
