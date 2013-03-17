require "bundler"
Bundler.setup
$:.unshift(File.expand_path("../../lib", __FILE__))
require 'bunny'
require 'background_bunnies'

class BackgroundBunnies::Workers::HelloWorker
  include BackgroundBunnies::Bunny
  group :default
  def process(job)
    p "Process: #{job.payload['name']}"
  end
end

connection = Bunny.new
BackgroundBunnies.configure(:default, connection)

producer = BackgroundBunnies::Workers::HelloWorker.create_producer connection
producer.enqueue({'name'=>"Hello"})

BackgroundBunnies.run :default
