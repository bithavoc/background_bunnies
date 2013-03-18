require "bundler"
Bundler.setup
$:.unshift(File.expand_path("../../lib", __FILE__))
require 'background_bunnies'
require 'bunny'

class BackgroundBunnies::Workers::IncrementCounter
  include BackgroundBunnies::Bunny
  group :default
  def process(job)
    step = job.payload['step'] || 1
    self.class.counter += step
    p "Incrementing: #{step} for a total of #{self.class.counter}"
  end

  def on_error(job, err)
    super # log the error to stderr
  end

  def self.counter
    @counter || 0
  end

  def self.counter=(c)
    @counter = c
  end

end

class BackgroundBunnies::Workers::ResetCounter
  include BackgroundBunnies::Bunny
  def process(job)
    BackgroundBunnies::Workers::IncrementCounter.counter = 0
    p "Reseting the count"
  end
end
