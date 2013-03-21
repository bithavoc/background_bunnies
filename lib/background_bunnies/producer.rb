require 'json'

module BackgroundBunnies
  class Producer
    attr_reader :channel
    attr_reader :queue
    attr_reader :queue_name
    attr_reader :connection

    def initialize(connection, queue_name)
      if connection.is_a? Symbol
        @connection = BackgroundBunnies.connections[connection]
      else
        @connection = connection
      end
      @queue_name = queue_name.to_s
      @channel = @connection.create_channel
      @queue = @connection.queue(@queue_name)
    end

    #
    # Publishes a Job for the Worker
    #
    def enqueue(payload)
      @queue.publish(JSON.generate(payload), :routing_key => @queue.name)
    end

  end
end
