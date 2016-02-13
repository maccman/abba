require 'rubygems'
require 'bundler'

Bundler.require
$: << settings.root

require 'sinatra'
require 'sinatra/config_file'
require 'active_support/json'
require 'app/abba'
require 'stylus/sprockets'

config_file 'config.yml'

configure do
  ActiveSupport.escape_html_entities_in_json = true

  MongoMapper.setup({
    'production'  => {'uri' => ENV['MONGOHQ_URL'] || ENV['MONGOLAB_URI']},
    'development' => {'uri' => 'mongodb://localhost:27017/abba-development'}
  }, settings.environment.to_s)

  env = Sprockets::Environment.new(settings.root)

  env.append_path('app/assets/javascripts')
  env.append_path('app/assets/stylesheets')
  env.append_path('vendor/assets/javascripts')

  Stylus.setup(env)

  set :sprockets, env
  set :views, 'app/views'
  set :erb, :escape_html => true
  set :username, ENV["ABBA_USERNAME"] unless ENV["ABBA_USERNAME"].nil?
  set :password, ENV["ABBA_PASSWORD"] unless ENV["ABBA_PASSWORD"].nil?
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

  def selected(value, present)
    ' selected ' if value == present
  end

  def required(*atts)
    atts.each do |a|
      if !params[a] || params[a].empty?
        halt 406, "#{a} required"
      end
    end
  end

  def protected!
    unless authorized?
      response['WWW-Authenticate'] = %(Basic realm="Testing HTTP Auth")
      throw(:halt, [401, "Not authorized\n"])
    end
  end

  def authorized?
    return true if !settings.username?

    auth =  Rack::Auth::Basic::Request.new(request.env)
    return false unless auth.provided? && auth.basic? && auth.credentials

    auth.credentials == [settings.username, settings.password]
  end

  def ssl_enforce!
    if !request.secure? && settings.ssl
      redirect "https://#{request.host}#{request.fullpath}"
    end
  end
end

configure :production do
  before '/admin/*' do
    ssl_enforce!
  end

  before '/admin/*' do
    protected!
  end
end

# Router

get '/assets/*' do
  env['PATH_INFO'].sub!(%r{^/assets}, '')
  settings.sprockets.call(env)
end

get '/admin/experiments' do
  @experiments = Abba::Experiment.all
  erb :experiments
end

get '/admin/experiments/:id/chart', :provides => 'application/json' do
  required :start_at, :end_at

  experiment = Abba::Experiment.find(params[:id])
  start_at   = Date.to_mongo(params[:start_at]).beginning_of_day
  end_at     = Date.to_mongo(params[:end_at]).end_of_day
  tranche    = params[:tranche].present? ? params[:tranche].to_sym : nil

  experiment.granular_conversion_rate(
    start_at: start_at, end_at: end_at, tranche: tranche
  ).to_json
end

put '/admin/experiments/:id/toggle' do
  @experiment = Abba::Experiment.find(params[:id])
  @experiment.running = !@experiment.running
  @experiment.save
  200
end

get '/admin/experiments/:id' do
  @experiment = Abba::Experiment.find(params[:id])
  redirect('/admin/experiments') and return unless @experiment

  @start_at   = Date.to_mongo(params[:start_at]) if params[:start_at].present?
  @end_at     = Date.to_mongo(params[:end_at]) if params[:end_at].present?
  @start_at ||= [@experiment.created_at, 30.days.ago].max
  @end_at   ||= Time.now.utc

  @start_at   = @start_at.beginning_of_day
  @end_at     = @end_at.end_of_day
  @tranche    = params[:tranche].present? ? params[:tranche].to_sym : nil

  @variants   = Abba::VariantPresentor::Group.new(
    @experiment, start_at: @start_at,
    end_at: @end_at, tranche: @tranche
  )

  @params = {
    start_at: @start_at.strftime('%F'),
    end_at:   @end_at.strftime('%F'),
    tranche:  @tranche
  }

  erb :experiment
end

delete '/admin/experiments/:id' do
  @experiment = Abba::Experiment.find(params[:id])
  @experiment.destroy

  redirect '/admin/experiments'
end

get '/admin' do
  redirect '/admin/experiments'
end

get '/' do
  redirect '/admin/experiments'
end
