require 'json'

module BackgroundBunnies
  class Broadcaster
    attr_reader :queue_name
    attr_reader :connection
    attr_reader :exchange

    def initialize(connection_or_group, queue_name)
      @connection = BackgroundBunnies.connect connection_or_group
      @queue_name = queue_name.to_s
      @channel = @connection.create_channel
      @exchange = @channel.fanout(BackgroundBunnies.broadcast_exchange_name(queue_name))
    end

    #
    # Publishes a Job for the Worker
    #
    def enqueue(payload)
      @exchange.publish(JSON.generate(payload))
    end

  end
end
