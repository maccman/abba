require 'rubygems'
require 'bundler'

Bundler.require
$: << settings.root

require 'sinatra'
require 'sinatra/config_file'
require 'active_support/json'
require 'app/abba'

require 'newrelic_rpm'

config_file 'config.yml'

configure do
  ActiveSupport.escape_html_entities_in_json = true

  if File.file?(settings.mongo_config_file)
    config = YAML.load(ERB.new(File.read(settings.mongo_config_file)).result)
    MongoMapper.setup(config, settings.environment.to_s)
  else
    MongoMapper.setup({
      'production'  => {'uri' => ENV['MONGOHQ_URL'] || ENV['MONGOLAB_URI']},
      'staging'  => {'uri' => ENV['MONGOHQ_URL'] || ENV['MONGOLAB_URI']},
      'development' => {'uri' => 'mongodb://localhost:27017/abba'}
    }, settings.environment.to_s)
  end

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
  required :application, :experiment, :variant

  experiment = Abba::Experiment.find_or_create_by_application_and_name(params[:application], params[:experiment])

  variant = experiment.variants.find_by_name(params[:variant])
  variant ||= experiment.variants.create!(:name => params[:variant], :control => params[:control])

  variant.start!(request) if experiment.running?

  prevent_caching
  send_blank
end

get '/complete', :provides => 'image/gif' do
  required :application, :experiment, :variant

  experiment = Abba::Experiment.find_or_create_by_application_and_name(params[:application], params[:experiment])

  variant = experiment.variants.find_by_name(params[:variant])
  variant.complete!(request) if variant && experiment.running?

  prevent_caching
  send_blank
end
