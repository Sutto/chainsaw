var Chainsaw = {
  
  Util:             {},
  spinderella:      null,
  processors:       {},
  loadExisting:     true,
  streamURL:        "",
  callbackCount:    0,
  onReadyCallbacks: [],
  connected:        false,
  host:             "",
  ports:            {base: 42340, websocket: 42342},
  debug:            false,
  
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
      realURL = url + "?callback=" + callbackJS;
    } else {
      realURL = url.replace("=?", "=" + callbackJS);
    }
    Chainsaw.log("Real URL is " + realURL);
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
    Chainsaw.log("Got url for", stream_identifier, "-", baseURL)
    return baseURL;
  },
  
  subscribe: function(channel) {
    this.spinderella.client.subscribe(["chainsaw/" + channel]);
  },
  
  watch: function(stream, loadExisting) {
    Chainsaw.log("Calling watch with stream =", stream, "and loadExisting =", loadExisting);
    if(loadExisting !== false && loadExisting !== true) loadExisting = this.loadExisting;
    var self = this;
    var callback = function() { self.subscribe(stream); };
    Chainsaw.log("Watching", stream, "and load existing is", loadExisting)
    if(loadExisting) {
      this.loadJSONP(this.urlForStream(stream), function(data) {
        var l = data.length;
        for(var i = l; i > 0; i--) {
          Chainsaw.receiveFromStream(data[i - 1], stream);
        }
        callback();
      });
    } else {
      callback();
    };
  },
  
  watchAll: function() {
    var l = arguments.length;
    for(var i = 0; i < l; i++) this.watch(arguments[i]);
  },
  
  onMessage: function(name, func) {
    if(typeof(func) != "function") return;;
    this.processors[name] = func;
  },
  
  onReady: function(f) {
    if(typeof(f) == "function") this.onReadyCallbacks.push(f);
  },
  
  ready: function() {
    Chainsaw.log("Invoking the onReady callbacks");
    var l = this.onReadyCallbacks.length;
    for(var i = 0; i < l; i++) this.onReadyCallbacks[i]();
    this.onReadyCallbacks = [];
  },
  
  alias: function(from, to) {
    this.onMessage(to, function(m, log) {
      Chainsaw.processors[from](msg, log);
    });
  },
  
  init: function(host, ports) {
    if(this.spinderella != null) return;
    if(!host) host = this.host;
    if(ports === undefined || ports === null) ports = this.ports;
    this.spinderella = Spinderella.create(host, ports);
    var self = this;
    this.spinderella.onMessage(function() {
      self.receiveMessage.apply(self, arguments);
    });
  },
  
  connect: function(f) {
    if(this.connected) return;
    Chainsaw.log("Adding onready callback")
    this.onReady(f);
    Chainsaw.log("Calling init()")
    this.init();
    var self = this;
    Chainsaw.log("Preparing to start spinderella connection.");
    this.spinderella.connect(function() {
      Chainsaw.log("Spinderella Connected!");
      Chainsaw.connected = true;
      Chainsaw.ready();
    });
  },
  
  receiveMessage: function(content, type, data) {    
    Chainsaw.log(content, type, data);
    // Anything not to a specific channel is counted as an eval.
    switch(type) {
    case "channel":
      this.receiveFromStream(JSON.parse(content), data["channel"].replace(/^chainsaw\//, ''))
      break;
    default:
      eval(content);
      break;
    }
  },
  
  receiveFromStream: function(message, stream) {
    var processor = this.processors[stream];
    // Execute blocks in the scope of Chainsaw.Util to make it easier
    // to use helpers.
    if(processor)
      with(this.Util) {  processor(message, stream); }
  },
  
  log: function() {
    if(!Chainsaw.debug || console == undefined || console.log == undefined) return;
    var args = ["[CHAINSAW]"].concat(Array.prototype.slice.apply(arguments));
    console.log.apply(console, args);
  }
  
};

Spinderella.log = Chainsaw.log;