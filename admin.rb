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

helpers do
  def title(value = nil)
    @title = value if value
    @title ? "Abba - #{@title}" : "Abba"
  end

  def dir(value)
    return if !value || value.zero?
    value > 0 ? 'positive' : 'negative'
  end
end

# Router

get '/' do
  redirect '/experiments'
end

get '/experiments' do
  @experiments = Abba::Experiment.all
  erb :experiments
end

get '/experiments/:id/chart', :provides => 'application/json' do
  @experiment = Abba::Experiment.find(params[:id])
  start_at    = @experiment.created_at.beginning_of_day
  end_at      = Time.now.utc
  @experiment.granular_conversion_rate(start_at, end_at).to_json
end

get '/experiments/:id' do
  @experiment = Abba::Experiment.find(params[:id])
  @variants   = @experiment.variants.all
  @variants   = @variants.sort_by(&:conversion_rate).reverse
  erb :experiment
end