require 'rubygems'
require 'bundler'

Bundler.require
$: << settings.root

require 'sinatra'
require 'active_support/json'
require 'app/abba'

configure do
  ActiveSupport.escape_html_entities_in_json = true

  MongoMapper.setup({
    'production'  => {'uri' => ENV['MONGOHQ_URL'] || ENV['MONGOLAB_URI']},
    'development' => {'uri' => 'mongodb://localhost:27017/abba-development'}
  }, settings.environment.to_s)

  env = Sprockets::Environment.new(settings.root)
  env.append_path('app/assets/javascripts')
  set :sprockets, env
end

helpers do
  def prevent_caching
    headers['Cache-Control'] = 'no-cache, no-store'
  end

  def send_blank
    send_file './public/blank.gif'
  end

  def required(*atts)
    atts.each do |a|
      if !params[a] || params[a].empty?
        halt 406, "#{a} required"
      end
    end
  end
end

get '/v1/abba.js', :provides => 'application/javascript' do
  settings.sprockets['client/index'].to_s
end

get '/start', :provides => 'image/gif' do
  required :experiment, :variant

  experiment = Abba::Experiment.find_or_create_by_name(params[:experiment])

  variant = experiment.variants.find_by_name(params[:variant])
  variant ||= experiment.variants.create!(:name => params[:variant], :control => params[:control])

  variant.start!(request) if experiment.running?

  prevent_caching
  send_blank
end

get '/complete', :provides => 'image/gif' do
  required :experiment, :variant

  experiment = Abba::Experiment.find_or_create_by_name(params[:experiment])

  variant = experiment.variants.find_by_name(params[:variant])
  variant.complete!(request) if variant && experiment.running?

  prevent_caching
  send_blank
end