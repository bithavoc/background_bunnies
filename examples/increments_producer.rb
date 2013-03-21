require_relative 'increments'
require 'thread'
connection = Bunny.new
BackgroundBunnies::configure(:default, connection)

producer = BackgroundBunnies::Workers::IncrementCounter.create_producer :default
step = 0.1
while true 
  step += 0.1
  sleep 1
  producer.enqueue({'step'=>step})
  p "Enqueued #{step}"
end
