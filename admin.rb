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

  set :views, settings.root + '/app/views'
  set :show_exceptions, true
  set :erb, :escape_html => true
end

# Router

get '/' do
  @tests = Abba::Test.all
  erb :tests
end

get '/test/:name' do
  @test     = Abba::Test.find_by_name!(params[:name])
  @variants = @test.variants.all
  erb :test
end