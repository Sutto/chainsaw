module Chainsaw
  class StreamPublisher
    SEPERATOR = "\r\n".freeze
    
    def initialize(options = {})
      @options = options
      @host    = (options[:host] || "localhost")
      @port    = (options[:port] || 42341).to_i
    end
    
    def publish(event)
      channel_name = "chainsaw/#{event.stream_identifier}".to_json
      broadcast_json = JSON.dump({
        "action" => "broadcast",
        "data"   => {
          "message" => event.message,
          "type"    => "channel",
          "channel" => channel_name
        }
      })
      # TODO: actually broadcast the json
    end
    
  end
end