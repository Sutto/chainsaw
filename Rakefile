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
             'chainsaw/base.js' => 'chainsaw/base.min.js',
             'chainsaw/util.js' => 'chainsaw/util.min.js'
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

# Deploy
namespace :deploy do
  
  def config(key)
    (@config ||= YAML.load_file("config/deploy.yml"))[key.to_s]
  end
  
  # Hooks as needed
  
  task :local_before do
  end
  
  task :local_after do
  end
  
  task :remote_before do
  end
  
  task :remote_after do
  end
  
  # Actual deploy
  
  desc "Runs a local deploy"
  task :local do
    Rake::Task["deploy:local_before"].invoke
    system "gem bundle"
    if File.exist?("tmp/pids/unicorn.pid")
      begin
        pid = File.read("tmp/pids/unicorn.pid").to_i
        Process.kill(:USR2, pid)
      rescue Errno::ENOENT, Errno::ESRCH
      end
      puts "Found pid, attempted to restart."
    else
      puts "Couldn't find a pid."
    end
    Rake::Task["deploy:local_after"].invoke
  end
  
  desc "Runs a remote deploy"
  task :remote do
    Rake::Task["deploy:remote_before"].invoke
    system "ssh #{config(:user)}@#{config(:host)} 'cd #{config(:app)} && git pull && rake deploy:local RAILS_ENV=production'"
    Rake::Task["deploy:remote_after"].invoke
  end
  
end
 
task :deploy => "deploy:remote"