require File.join(File.dirname(__FILE__), "lib", "chainsaw")
require 'rack/deflater'

Chainsaw.boot!

use Rack::Deflater
run Chainsaw::WebApp