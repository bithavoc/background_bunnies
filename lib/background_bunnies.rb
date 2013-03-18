require "background_bunnies/version"
require "background_bunnies/logger"
require "background_bunnies/bunny"
require "background_bunnies/producer"
require "background_bunnies/job"
require "background_bunnies/workers"
require "thread"

module BackgroundBunnies

  class << self

    #
    # Group Connection Configurations
    #
    def configurations
      @configs || @configs = {}
    end

    #
    # Configures the connection of a group
    #
    def configure(group, connection)
      info "Configuring #{group} connection"
      configurations[group] = connection
      if connection.status == :not_connected
        connection.start
      end
    end

    #
    # Runs all the tasks in the given group and waits.
    #
    def run(group)
      connection = configurations[group]
      klasses = describe_group(group)
      info "Running #{group} workers: #{ klasses.join(',') }"
      klasses.each do |klass|
        instance = klass.new
        instance.start connection
        info "Started worker: #{klass.demodulized_class_name}"
      end
      Thread.current.join
    end

    #
    # Describe types in BackgroundBunnies::Workers::* in the given group.
    #
    def describe_group(group)
      worker_names = BackgroundBunnies::Workers.constants.collect! { |worker_name| BackgroundBunnies::Workers.const_get(worker_name) }
      worker_names.select {|klass| klass.group_name == group }
    end

  end

end
