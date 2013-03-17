require 'bunny'
require_relative 'test_helper'

describe BackgroundBunnies::Bunny do
  describe :queue_name do

    it "should return the default name based on the worker class name" do 
      class WorkerDefault
        include BackgroundBunnies::Bunny
      end
      worker = WorkerDefault.new
      worker.queue_name.must_equal "WorkerDefault"
    end

    it "should return the custom name or symbol is set" do 
      class WorkerNonDefault
        include BackgroundBunnies::Bunny
        queue :explicit_queue_name
      end
      worker = WorkerNonDefault.new
      worker.queue_name.must_equal "explicit_queue_name"
    end

  end
  
  describe :start do
    it "should subscribe to queue" do
      class StartTest
        include BackgroundBunnies::Bunny
      end
      connection_klass = Struct.new("ConnectionStub", :last_channel) do
        def create_channel
          channel_klass = Struct.new("StubChannel", :hook_queue_name) do
            def queue(name)
              self.hook_queue_name= name
              queue_klass = Struct.new("StubQueue", :options) do
                def subscribe(options, &block)
                  self.options = options
                end
              end
              queue_klass.new
            end
          end
          self.last_channel = channel_klass.new
        end
        
        def start

        end
      end
      connection = connection_klass.new
      connection.start
      worker = StartTest.new
      worker.start connection
      worker.channel.must_equal connection.last_channel
      worker.channel.hook_queue_name.must_equal "StartTest"
      worker.queue.options[:block].must_equal false
      worker.queue.options[:ack].must_equal true
    end
  end

  describe :process, "success" do
    it "should ack success jobs" do
      class StartTest
        include BackgroundBunnies::Bunny
        attr_reader :product_id

        def process(job)
          @product_id = job.payload['product_id']
        end

      end
      connection_klass = Struct.new("StubConnectionSuccess") do
        def create_channel
          channel_klass = Struct.new("StubChannelSuccess", :delivery_tag) do
            def queue(name)
              queue_klass = Struct.new("StubQueueSuccess", :options) do
                def subscribe(options, &block)
                  self.options = options
                  yield(Struct.new(:delivery_tag).new("tag0"), {}, JSON.generate({:product_id=>560}))
                end
              end
              queue_klass.new
            end

            def ack(delivery_tag, multiple)
              self.delivery_tag = delivery_tag
            end

          end
          channel_klass.new
        end
        def start

        end
      end
      connection = connection_klass.new
      connection.start
      worker = StartTest.new
      worker.start connection
      worker.channel.delivery_tag.must_equal "tag0"
      worker.product_id.must_equal 560
    end
  end

  describe :process, "exceptions" do
    it "should not ack failed jobs" do
      class StartTest
        include BackgroundBunnies::Bunny

        def process(job)
          raise "some error"
        end

      end
      connection_klass = Struct.new("StubExceptionsConnections") do
        def create_channel
          channel_klass = Struct.new("StubChannelExceptions", :delivery_tag) do
            def queue(name)
              queue_klass = Struct.new("StubQueueExceptions", :options) do
                def subscribe(options, &block)
                  self.options = options
                  yield(Struct.new(:delivery_tag).new("tag0"), {}, JSON.generate({:product_id=>1}))
                end
              end
              queue_klass.new
            end

            def ack(delivery_tag, multiple)
              self.delivery_tag = delivery_tag
            end

          end
          channel_klass.new
        end

        def start

        end
      end
      connection = connection_klass.new
      connection.start
      worker = StartTest.new
      worker.start connection
      worker.channel.delivery_tag.must_be_nil
    end
  end

end

