require 'rubygems'
require 'bundler'

Bundler.require
$: << settings.root

require 'sinatra'
require 'sinatra/reloader' if development?
require 'active_support/json'
require 'app/abba'

configure do
  ActiveSupport.escape_html_entities_in_json = true

  MongoMapper.setup({
    'production'  => {'uri' => ENV['MONGOHQ_URL']},
    'development' => {'uri' => 'mongodb://localhost:27017/abba-development'}
  }, settings.environment.to_s)

  set :sprockets, Sprockets::Environment.new
  settings.sprockets.append_path 'app/assets/javascripts'
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
        halt "#{a} required"
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
  variant = experiment.variants.find_or_create_by_name(params[:variant])
  variant.start!(request)

  prevent_caching
  send_blank
end

get '/complete', :provides => 'image/gif' do
  required :experiment, :variant

  experiment = Abba::Experiment.find_or_create_by_name(params[:experiment])
  variant = experiment.variants.find_or_create_by_name(params[:variant])
  variant.complete!(request)

  prevent_caching
  send_blank
end