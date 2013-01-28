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

  Catapult.environment.append_path(settings.root  + '/app/assets/javascripts')
  Catapult.environment.append_path(settings.root  + '/app/assets/stylesheets')

  set :views, settings.root + '/app/views'
  set :show_exceptions, true
  set :erb, :escape_html => true
end

# Router

get '/' do
  redirect '/experiments'
end

get '/experiments' do
  @experiments = Abba::Experiment.all
  erb :experiments
end

get '/experiment/:name' do
  @experiment = Abba::Experiment.find_by_name!(params[:name])
  @variants   = @experiment.variants.all
  @variants   = @variants.sort_by(&:conversion_rate).reverse
  @variant_graph = @experiment.granular_conversion_rate(7.days.ago, Time.current)

  erb :experiment
end