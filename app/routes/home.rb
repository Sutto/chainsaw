require 'json'

class Main
  
  get '/' do
    'Powered by Chainsaw.'
  end
  
  get '/latest' do
    queues = []
    if params[:q].to_s == ""
      queues = LogQueue.all.all
    else
      queues = params[:q].to_s.split(",").map { |q| LogQueue.named(q.strip) }
    end
    hash = {}
    queues.each { |q| hash[q.name] = q.recent }
    json = JSON.dump(hash.to_json)
    json = "#{params[:callback]}(#{json});" if params[:callback]
    content_type :json
    return json
  end
  
end
