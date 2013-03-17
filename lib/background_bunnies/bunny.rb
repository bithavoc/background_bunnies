require 'thread'
require_relative 'job'

module BackgroundBunnies
  module Bunny

    module BunnyConfigurators

      def group(group_name)
        @group_name = group_name
      end

      def queue(queue_name)
        @queue_name = queue_name.to_s
      end

      def group_name
        @group_name || :default
      end

      def queue_name
        @queue_name || demodulized_class_name
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

    attr_reader :channel
    attr_reader :queue
    attr_reader :consumer

    #
    # Starts the Worker
    #
    def start(connection)
      @channel = connection.create_channel
      @queue = @channel.queue(queue_name)
      @consumer = @queue.subscribe(block: false, ack: true) do |info, properties, payload|
        job = Job.new(JSON.parse!(payload), info, properties)
        err = nil
        begin 
          self.process(job) 
        rescue =>e
          err = e
        end
        unless err
          @channel.ack(info.delivery_tag, false)
        end
      end
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
