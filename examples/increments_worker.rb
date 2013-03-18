require_relative "increments"

connection = Bunny.new
connection.start
BackgroundBunnies.configure(:default, connection)

BackgroundBunnies.run :default
