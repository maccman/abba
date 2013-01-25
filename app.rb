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
  settings.sprockets['index'].to_s
end

get '/start', :provides => 'image/gif' do
  required :test, :variant

  test    = Abba::Test.find_or_create_by_name(params[:test])
  variant = test.variants.find_or_create_by_name(params[:variant])
  variant.start!(request.env)

  send_blank
end

get '/complete', :provides => 'image/gif' do
  required :test, :variant

  test    = Abba::Test.find_or_create_by_name(params[:test])
  variant = test.variants.find_or_create_by_name(params[:variant])
  variant.complete!(request.env)

  send_blank
end