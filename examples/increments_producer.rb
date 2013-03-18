require_relative 'increments'
require 'thread'
connection = Bunny.new
connection.start

producer = BackgroundBunnies::Workers::IncrementCounter.create_producer connection
while true 
  sleep 0.1
  producer.enqueue({'step'=>2})
end
