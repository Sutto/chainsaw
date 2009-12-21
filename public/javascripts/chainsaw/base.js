var Chainsaw = {
  
  spinderella:      null,
  processors:       {},
  loadExisting:     false,
  streamURL:        "",
  callbackCount:    0,
  onReadyCallbacks: [],
  connected:        false,
  host:             "",
  port:             {base: 42340, websocket: 42342},
  
  loadJSONP: function(url, callback) {
    var id = this.callbackCount++;
    var domID = "chainsaw-callback-" + id;
    var callbackID = "jsonpCallback" + id; 
    Chainsaw[callbackID] = function(data) {
      if(typeof(callback) == 'function') callback(data);
      // Cleanup after ourselves.
      delete Chainsaw[callbackID];
      var el = document.getElementById(domID);
      if(el) {
        el.parentElement.removeChild(el);
        for(var i in el) delete el[i];
      }
    };
    // Compute the real URL
    var realURL;
    var callbackJS = "Chainsaw." + callbackID;
    if(url.indexOf('?') < 0) {
      realURL = url = "?callback=" + callbackJS;
    } else {
      realURL = url.replace("=?", "=" + callbackJS);
    }
    // Create the script tag
    var script  = document.createElement("script");
    script.type = 'text/javascript';
    script.id   = domID;
    script.src  = realURL;
    var head = document.getElementsByTagName('head')[0];
    head.appendChild(script);
  },
  
  urlForStream: function(stream_identifier, ext) {
    var baseURL = this.streamURL.replace("IDENTIFIER", stream_identifier);
    if(ext) baseURL += ext;
    return baseURL;
  },
  
  subscribe: function(channel) {
    this.spinderella.client.subscribe(["chainsaw/" + channel]);
  },
  
  watch: function(stream, loadExisting) {
    if(loadExisting !== false && loadExisting !== true) loadExisting = this.loadExisting;
    var self = this;
    var callback = function() { self.subscribe(stream); };
    if(loadExisting) {
      this.loadJSONP(this.urlForStream(stream), function(data) {
        //.replace(/^chainsaw\//, '')
        var l = data.length;
        for(var i = l; i > 0; i--) {
          this.receiveFromStream(data[i - 1], stream);
        }
        callback();
      });
    } else {
      callback();
    };
  },
  
  watchAll: function() {
    var l = arguments.length;
    for(var i = 0; i < l; i++) this.watchAll(arguments[i]);
  },
  
  onMessage: function(name, func) {
    if(typeof(func) != "function") return;;
    this.processors[name] = func;
  },
  
  onReady: function(f) {
    if(typeof(f) == "function") this.onReadyCallbacks.push(f);
  },
  
  ready: function() {
    var l = this.onReadyCallbacks.length;
    for(var i = 0; i < l; i++)
      this.onReadyCallbacks[i]();
    this.onReadyCallbacks = [];
  };
  
  alias: function(from, to) {
    this.onMessage(to, function(m, log) {
      Chainsaw.processors[from](msg, log);
    });
  },
  
  init: function(host, ports) {
    if(this.spinderella != null) return;
    if(!host) host = this.host;
    if(!port) ports = this.ports;
    this.spinderella = Spinderella.create(host, ports);
    var self = this;
    this.spinderella.onMessage(function() {
      self.receiveMessage.apply(self, arguments);
    });
  }
  
  connect: function(f) {
    if(this.connected) return;
    this.onReady(f);
    this.init();
    var self = this;
    this.spinderella.connect(function() {
      Chainsaw.connected = true;
      Chainsaw.ready();
    });
  }
  
  receiveMessage: function(content, type, data) {    
    switch(type) {
      // Anything not to a specific channel is counted as an eval.
      case "all", "users", "channels":
        eval(content);
        break;
      case "channel":
        this.receiveFromStream(JSON.parse(content), data["channel"].replace(, /^chainsaw\//, ''))
        break;
    }
  },
  
  receiveFromStream: function(message, stream) {
    var processor = this.processors[stream];
    if(processor) processor(message, stream);
  }
  
};

