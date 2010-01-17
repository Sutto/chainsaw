require 'fileutils'

module Chainsaw
  class WebApp < Sinatra::Base
    
    class Rescuer
      
      REQUEST_ERROR_JSON = JSON.dump({'error' => 'An unknown error occured processing your request.'}).freeze
      
      def initialize(app)
        @app = app
      end
      
      def call(env)
        self.dup._call(env)
      end
      
      def _call(env)
        begin
          @app.call(env)
        rescue Exception => e
          response_for_exception(e, env)
        end
      end
      
      protected
      
      def response_for_exception(e, env)
        logger = Chainsaw.logger
        logger.fatal "Exception on Request: #{e.class.name} - #{e.message}"
        e.backtrace.each do |line|
          logger.fatal "-> #{line}"
        end
        logger.fatal "Sending rescued response"
        # Send a response
        response = Rack::Response.new
        request  = (env['rack.request'] ||= Rack::Request.new(env))
        response.status = 500
        if Chainsaw.env.development?
          response['Content-Type'] = "text/html"
          error_name = "#{e.class.name} - #{e.message}"
          response.write "<html><head><title>#{error_name}</title></head>"
          response.write"<body><h1>#{error_name}</h1><pre>"
          e.backtrace.each do |line|
            response.write "#{line}\r\n"
          end
          response.write "</pre></body></html>"
        else
          callback = request.params["callback"]
          if callback
            response["Content-Type"] = "application/javascript"
            response.write("#{callback}(#{REQUEST_ERROR_JSON});");
          else
            response["Content-Type"] = "application/json"
            response.write REQUEST_ERROR_JSON
          end
        end
        response.finish
      end
      
    end
    
    INVALID_MESSAGE_JSON   = JSON.dump({'error' => 'Invalid message provided'}).freeze
    STREAM_PERMISSION_JSON = JSON.dump({'error' => 'You do not have permission to publish to this stream'}).freeze
    
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
    
    use Rescuer
    
    get '/' do
      auto_wrap(@about ||= JSON.dump({
        "name"    => "Chainsaw",
        "version" => Chainsaw.version,
        "ruby"    => RUBY_VERSION
      }).freeze)
    end
    
    get '/j/chainsaw.js' do
      content_type :js
      compressed_configuration_js
    end
    
    get '/j/configuration.js' do
      content_type :js
      erb :configuration
    end
    
    # Create a stream page
    post '/s' do
      stream = Chainsaw::Stream.from_hash(params.dup)
      if stream.save
        auto_wrap(JSON.dump({
          :result      => :success,
          :stream      => stream.as_hash(true),
          :stats_url   => live_url("/s/#{stream.identifier}"),
          :embed_url   => live_url("/s/#{stream.identifier}/.js"),
          :recent_url  => live_url("/s/#{stream.identifier}/recent"),
          :publish_url => live_url("/s/#{stream.identifier}/publish")
        }))
      else
        status 422
        auto_wrap(JSON.dump({
          :result => :invalid,
          :stream => stream.as_hash
        }))
      end
    end
    
    # Stream configuration page
    get '/s/:identifier' do
      auto_wrap JSON.dump({
        'recent_url'  => live_url("/s/#{params[:identifier]}/recent"),
        'publish_url' => live_url("/s/#{params[:identifier]}/publish"),
        'event_count' => Chainsaw::Event.count(:stream_identifier => params[:identifier])
      })
    end
    
    get '/s/:identifier/.js' do
      content_type :js
      @stream = Chainsaw::Stream.first(:identifier => params[:identifier])
      message = [compressed_configuration_js, "\r\n"];
      if @stream.blank?
        run = 'Chainsaw.run = function() {'
        run << (params[:verbose] ? "alert('Woops! it seams someone is trying to load an invalid Chainsaw stream.');" : '')
        run << '};'
        message << run;
      else
        message << erb(:stream_configuration);
      end
      message.join.gsub(/\n\s+\n/, "\n")
    end
    
    # Gets a list of recent entries
    get '/s/:identifier/recent' do
      events = Chainsaw::Event.recent_for(params[:identifier], constrained_limit(1, 1000, 25, params[:limit]))
      auto_wrap jsonify(events)
    end
    
    # Publish an item to a stream
    post '/s/:identifier/publish' do
      stream = Chainsaw::Stream.first(:identifier => params[:identifier])
      if stream && stream.api_key == params[:api_key]
        event = stream.build_event(:message => params[:message])
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
      
      def asset_url(path)
        asset_path = Chainsaw.root.join("public", path.gsub(/^\//, ''))
        mtime = (asset_path.exist? ? asset_path.mtime : Time.now).to_i
        [live_url(path), mtime].join("?")
      end
      
      def compiler
        @@compiler ||= Closure::Compiler.new
      end
      
      def compress_js(javascript)
        Chainsaw.env.development? ? javascript : compiler.compile(javascript)
        javascript
      end
      
      def raw_spinderella_js
        @@raw_spinderella_js ||= begin
          buffer = ""
          buffer << File.read(Chainsaw.root.join("public", "javascripts", "json2.js"))
          buffer << File.read(Chainsaw.root.join("public", "javascripts", "spinderella.js"))
          buffer
        end
      end
      
      def raw_chainsaw_js
        @@raw_chainsaw_js ||= begin
          buffer = ""
          buffer << File.read(Chainsaw.root.join("public", "javascripts", "chainsaw", "base.js"))
          buffer << erb(:configuration)
          buffer
        end
      end
      
      def compressed_configuration_js
        @@compressed_configuration_js ||= compress_js([raw_spinderella_js, raw_chainsaw_js].join("\n\n"))
      end
      
    end
    
  end
end