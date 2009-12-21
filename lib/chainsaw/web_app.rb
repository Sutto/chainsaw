require 'fileutils'
require 'closure-compiler'

module Chainsaw
  class WebApp < Sinatra::Base
    
    INVALID_MESSAGE_JSON   = JSON.dump({'error' => 'Invalid message provided'}).freeze
    STREAM_PERMISSION_JSON = JSON.dump({'error' => 'You do not have permission to publish to this stream'}).freeze
    
    def self.serve!
    end
    
    def self.redirect_stdio!
      log_dir = Chainsaw.root.join("log")
      FileUtils.mkdir_p(log_dir)
      log = File.open(log_dir.join("#{Chainsaw.env}.log"), "a+")
      $stdout.reopen(log)
      $stderr.reopen(log)
    end
    
    set(:environment, Proc.new { Chainsaw.env.to_sym })
    set(:root,        Proc.new { Chainsaw.root.to_s })
    set(:public,      Proc.new { Chainsaw.root.join("public").to_s })
    set(:views,       Proc.new { Chainsaw.root.join("views").to_s })
    set(:app_file,    __FILE__)
    set(:static,      true)
    
    disable :run
    
    get '/' do
      @about ||= JSON.dump({
        "name"    => "Chainsaw",
        "version" => Chainsaw.version,
        "ruby"    => RUBY_VERSION
      }).freeze
    end
    
    get '/j/configuration.js' do
      erb :configuration
    end
    
    # Stream configuration page
    get '/s/:identifier' do
      auto_wrap JSON.dump({
        'recent_url'  => live_url("/s/#{params[:identifier]}/recent"),
        'publish_url' => live_url("/s/#{params[:identifier]}/publish"),
        'event_count' => Chainsaw::Event.count(:stream_identifier => params[:identifier])
      })
    end
    
    # Gets a list of recent entries
    get '/s/:identifier/recent' do
      events = Chainsaw::Event.recent_for(params[:identifier], constrained_limit(1, 1000, 25, params[:limit]))
      auto_wrap jsonify(events)
    end
    
    # Publish an item to a stream
    post '/s/:identifier/publish' do
      stream = Chainsaw::Stream.first(:identifier => params[:identifier])
      if stream.api_key == params[:api_key]
        event = stream.build_event(:message => get_request_body)
        if event.save
          status 200
          auto_wrap JSON.dump('identifier' => stream.identifier)
        else
          status 422
          auto_wrap INVALID_MESSAGE_JSON
        end
      else
        status 403
        auto_wrap STREAM_PERMISSION_JSON
      end
    end
    
    helpers do
    
      def constrained_limit(min, max, default, current)
        current = default if current.blank? || current.to_i == 0
        [max, [current.to_i, min].max].min
      end
    
      def jsonify(events)
        "[#{events.map { |e| e.message }.join(", ")}]"
      end
    
      def auto_wrap(json)
        if params[:callback]
          content_type :js
          "#{params[:callback]}(#{json});"
        else
          content_type :json
          json
        end
      end
      
      def live_url(path = "/")
        scheme, port = request.scheme, request.port
        url = scheme + "://"
        url << request.host
        if scheme == "https" && port != 443 || scheme == "http" && port != 80
          url << ":#{request.port}"
        end
        File.join(url, path)
      end
    
      def get_request_body
        body = request.body
        body.rewind if body.respond_to?(:rewind)
        body.read
      end
      
      def compiler
        @compiler ||= Closure::Compiler.new
      end
      
      def compress_js(javascript)
        compiler.compile(javascript)
      end
      
      def raw_spinderella_js
        @raw_spinderella_js ||= begin
          buffer = ""
          buffer << File.read(Chainsaw.root.join("public", "javascripts", "spinderella.js"))
          buffer << erb(:configuration)
          buffer
        end
      end
      
      def raw_chainsaw_js
        @raw_chainsaw_js ||= begin
          buffer = ""
          
          buffer
        end
      end
      
    end
    
  end
end