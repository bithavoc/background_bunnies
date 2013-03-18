require_relative 'increments'
require 'thread'
connection = Bunny.new
connection.start

producer = BackgroundBunnies::Workers::IncrementCounter.create_producer connection
step = 0.1
while true 
  step += 0.1
  sleep 1
  producer.enqueue({'step'=>step})
  p "Enqueued #{step}"
end
