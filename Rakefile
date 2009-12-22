task :environment do
  require File.join(File.dirname(__FILE__), "lib", "chainsaw")
  Chainsaw.boot!
end

# Compresses the javascript associated with Chainsaw
task :minify do
  require 'closure-compiler'
  compile_js 'jssocket.js'      => 'jssocket.min.js',
             'orbited.js'       => 'orbited.min.js',
             'json2.js'         => 'json2.min.js',
             'spinderella.js'   => 'spinderella.min.js',
             'chainsaw/base.js' => 'chainsaw/base.min.js'
end

def compile_js(opts = {})
  compiler = Closure::Compiler.new
  base = File.join(File.dirname(__FILE__), "public", "javascripts")
  opts.each_pair do |from, to|
    from = File.open(File.join(base, from), "r")
    File.open(File.join(base, to), "w+") do |f|
      f.write compiler.compile(from)
    end
  end
end