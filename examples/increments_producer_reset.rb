require_relative 'increments'

connection = Bunny.new
connection.start

producer = BackgroundBunnies::Workers::ResetCounter.create_producer connection
producer.enqueue({})
