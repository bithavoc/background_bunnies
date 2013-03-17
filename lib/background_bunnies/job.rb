module BackgroundBunnies
  class Job
    attr_reader :info
    attr_reader :properties
    attr_reader :payload

    def initialize(payload, info = nil, properties = nil)
      @info = info
      @properties = properties
      @payload = payload
    end
  end
end
