require "background_bunnies/version"
require "background_bunnies/logger"
require "background_bunnies/bunny"
require "background_bunnies/producer"
require "background_bunnies/job"
require "background_bunnies/workers"
require "thread"
require "bunny"
require "amqp"

module BackgroundBunnies

  class << self

    #
    # Group Connection Configurations
    #
    def configurations
      @configs || @configs = {}
    end

    DEFAULT_CONNECTION_OPTIONS={:threaded=>false}.freeze

    #
    # Configures the connection of a group
    #
    def configure(group, url, options = DEFAULT_CONNECTION_OPTIONS)
      info "Configuring #{group} connection with #{url} and options #{options}"
      configurations[group] = {
        :url=>url,
        :options=>options
      }
    end

    #
    # Creates a new connection based on a group configuration
    #
    def connect(connection_or_group, options=DEFAULT_CONNECTION_OPTIONS)
      unless connection_or_group.is_a? Symbol
        return connection_or_group
      end
      configuration = self.configurations[connection_or_group] || DEFAULT_CONNECTION_OPTIONS
      configuration = configuration.dup.merge!(options)
      raise "Unable to connect. Missing configuration for group #{connection_or_group}" unless configuration
      conn = ::Bunny.new(configuration[:url], configuration[:options])
      conn.start
      conn
    end

    #
    # Runs all the tasks in the given group and waits.
    #
    def run(group)
      klasses = describe_group(group)
      instances = []
      EventMachine.run do
        url = configurations[group][:url]
        puts "Group Connection: #{url}"
        connection = AMQP.connect(url)
        info "Running #{group} workers: #{ klasses.join(',') }"
        klasses.each do |klass|
          instance = klass.new
          instance.start connection
          info "Started worker: #{klass.demodulized_class_name}"
          instances << instance
        end
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
