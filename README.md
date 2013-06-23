# BackgroundBunnies

Background workers based on AMQP Bunny gem

## Installation

Add this line to your application's Gemfile:

    gem 'background_bunnies'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install background_bunnies
	
## How it Works

Background Bunnies are workers fed by producers and broadcasters.

* A producer will create jobs intended for bunnies of type `queue` and only one worker will process the job. This is the default configuration.
* A broadcasters will produce jobs intented for bunnies of type `broadcast` and every single worker will receive the same job.

## Work Queues

A work client uses AMQP queues and only one bunny will perform the job, this is known as a work queue. This is the default configuration for all the bunnies.

Example Bunny Worker:

	require 'background_bunnies'
	
	class BackgroundBunnies::Workers::ImageTransform
	  include BackgroundBunnies::Bunny
	  group :images

	  def process(job)
		image_url = job.payload[:image_url] # https://encrypted.google.com/images/srpr/logo4w.png
	    # perform image transformation here
	  end
	end
	
    BackgroundBunnies.configure(:main, "amqp://guest:guest@127.0.0.1")
	BackgroundBunnies.run(:images) # block forever while running the workers

Example Client:

    BackgroundBunnies.configure(:main, "amqp://guest:guest@127.0.0.1")
    producer = BackgroundBunnies::Workers::ImageTransform.create_producer :images
	producer.enqueue(image_path: "https://encrypted.google.com/images/srpr/logo4w.png")

## Broadcast

A broadcast client uses AMQP queues to `fanout` the same job across many worker bunnies, bunnies will receive the job when mode `broadcast` is used.

Example Bunny worker:

	require 'background_bunnies'
	
	class BackgroundBunnies::Workers::RelyMessage
	  include BackgroundBunnies::Bunny
	  type :broadcast # tell the bunny worker it should use queue as broadcast
	  group :messaging

	  def process(job)
		subject = job.payload[:subject] # "Spread this message across all the worker nodes"
	    # do your thing here
	  end
	end
	
	BackgroundBunnies.configure(:main, "amqp://guest:guest@127.0.0.1")
	BackgroundBunnies.run(:messaging) # block forever while running the workers

Example Client:

    BackgroundBunnies.configure(:main, "amqp://guest:guest@127.0.0.1")
    producer = BackgroundBunnies::Workers::RelyMessage.create_brodacaster :messaging
	producer.enqueue(subject: "Spread this message across all the worker nodes")

## Error Handling

In the case an exception is raised while executing the method `process`, the job will be put back on the queue so it can be processed in another time or by another worker. Even if the worker crashes, the job will be processed in another time or by another worker eventually.

Bunnies provide a method you could override to determinate which errors should cause the job to be requeued or skipped.

Return `true` if you want to skip the job, the default is requeue the job on every error.

    def on_error(job, err)
	  # true and the job will be skipped.
	  # false and the job will be requeued. This is the default.
    end


## Configuring Connection Strings

Bunnies will be executed together under the same configuration group. The default group is `:default`.

A group share the same connection uri across the producers, broadcasters and bunnies:

Example:

    BackgroundBunnies.configure(:default, "amqp://guest:guest@127.0.0.1")

## Executing a group of Workers

Instead initializing and running a single worker manually, background bunnies executes in groups.

	BackgroundBunnies.run(:default) # block forever while running the workers

## Workers as custom Rake Tasks

If you want to run your workers as a rake task in for example, a Rails app, you can create one as follows:

Create a file in `lib/tasks/images.rb`:

	namespace :mybunnies do
	  task :images=>:environment do
	    BackgroundBunnies.run(:images)
	  end
	end

You can then run from the command line:

	rake mybunnies:images

## Logging

In your worker bunnies you can use `log_error`, `log_warn` and `log_info` to log information formatted as part of BackgroundBunnies to `$stderr` and `$stdout`.

Example:

	def process(job)
	  log_error "An error occurred"
	  log_info "Something Happened"
	  log_warn "Beware of this"
	end

Output:

    [error] BackgroundBunnies -> Songs: An error occurred
    [info] BackgroundBunnies -> Songs: Something Happened
    [warn] BackgroundBunnies -> Songs: Beware of this
	

## Examples

Check `/examples`.

## LICENSE

MIT

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
