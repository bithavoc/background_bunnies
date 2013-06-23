require 'thread'
require 'bunny'
require 'amqp'
require 'socket'

require_relative 'job'

module BackgroundBunnies
  module Bunny
    DEFAULT_CONNECTION_OPTIONS = {:threaded=>true}

    module BunnyConfigurators
      def group(group_name)
        @group_name = group_name
      end

      def queue(queue_name)
        @queue_name = queue_name.to_s
      end

      def type(type)
        @type = type
      end

      def group_name
        @group_name || :default
      end

      def queue_name
        @queue_name || demodulized_class_name
      end

      def queue_type
        @type || :queue
      end

      def connection_options
        @connection_options || DEFAULT_CONNECTION_OPTIONS.dup
      end

      def connection_options=(options)
        @connection_options
      end

      def demodulized_class_name
        path = name
        if i = path.rindex('::')
          path[(i+2)..-1]
        else
          path
        end
      end

      def create_producer(connection)
        BackgroundBunnies::Producer.new(connection, queue_name)
      end

      def create_broadcaster(connection)
        BackgroundBunnies::Broadcaster.new(connection, queue_name)
      end

    end

    def self.included(base)
      base.extend(BunnyConfigurators)
    end

    #
    # Returns the name of the queue for the Worker
    #
    def queue_name
      self.class.queue_name
    end

    def queue_type
      self.class.queue_type
    end

    def connection_options
      self.class.connection_options
    end

    attr_reader :channel
    attr_reader :queue
    attr_reader :consumer
    attr_reader :exchange
    attr_reader :thread

    #
    # Starts the Worker with the given connection or group name
    #
    def start(connection_or_group)
      @connection = connection_or_group
      @channel = AMQP::Channel.new(@connection)
      queue_options = {}
      name = queue_name
      if queue_type == :broadcast
        queue_options[:exclusive] = true
        queue_options[:auto_delete] = true
        name = "#{Socket.gethostname}-#{Process.pid}-#{self.object_id}"
        @queue = @channel.queue(name, queue_options)
        @exchange = @channel.fanout(BackgroundBunnies.broadcast_exchange_name(queue_name))
        @queue.bind(@exchange)
      else
        queue_options[:durable] = true
        @queue = @channel.queue(queue_name, queue_options)
      end
      @consumer = @queue.subscribe(:ack=>true) do |metadata, payload|
        info = metadata
        properties = nil
        begin 
          job = Job.new(JSON.parse!(payload), info, properties)
          err = nil
          self.process(job) 
          metadata.ack
        rescue =>err
          # processing went wrong, requeing message
          job = Job.new(nil, info, properties) unless job
          unless on_error(job, err)
            metadata.reject(:requeue=>true)
          else
            metadata.ack
          end
        end
      end
    end

    def on_error(job, err)
      log_error "Error processing #{job.info.delivery_tag}: #{err.message}, #{err.backtrace.join('\n')}"
    end

    def log_error(a)
      BackgroundBunnies.error "#{queue_name}: #{a}"
    end

    def log_info(a)
      BackgroundBunnies.info "#{queue_name}: #{a}"
    end

    def log_warn(a)
      BackgroundBunnies.warn "#{queue_name}: #{a}"
    end

    #
    # Process a Job. Implemented by the class.
    #
    def process(job)

    end

    #
    # Starts the worker instance and blocks the current thread.
    #
    def run(connection)
      start connection
      Thread.current.join
    end

  end
end
