require File.join(File.dirname(__FILE__), "lib", "chainsaw")
require 'rack/deflater'

Chainsaw.boot!
Chainsaw::WebApp.redirect_stdio!

use Rack::Deflater
run Chainsaw::WebApp