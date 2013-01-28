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

  def required(*atts)
    atts.each do |a|
      if !params[a] || params[a].empty?
        halt "#{a} required"
      end
    end
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
  required :start_at, :end_at

  experiment = Abba::Experiment.find(params[:id])
  start_at   = Date.to_mongo(params[:start_at]).beginning_of_day
  end_at     = Date.to_mongo(params[:end_at]).end_of_day

  experiment.granular_conversion_rate(start_at: start_at, end_at: end_at).to_json
end

get '/experiments/:id' do
  @experiment = Abba::Experiment.find(params[:id])

  @start_at   = Date.to_mongo(params[:start_at]).beginning_of_day if params[:start_at]
  @end_at     = Date.to_mongo(params[:end_at]).end_of_day if params[:end_at]
  @start_at   ||= @experiment.created_at.beginning_of_day
  @end_at     ||= Time.now.utc

  @variants   = Abba::VariantPresentor::Group.new(@experiment, start_at: @start_at, end_at: @end_at)

  erb :experiment
end