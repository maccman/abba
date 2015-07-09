require 'rubygems'
require 'bundler'
Bundler.require(:default)

$LOAD_PATH << settings.root

require 'active_support/json'

require 'app/abba'
require 'app'
require 'admin'

configure do
  ActiveSupport.escape_html_entities_in_json = true

  # Configure MongoMapper
  mongo_config = YAML.load(ERB.new(File.read('mongo.yml')).result)
  MongoMapper.setup(mongo_config, settings.environment.to_s)

  # Configure Sprockets
  env = Sprockets::Environment.new(settings.root)
  env.append_path('app/assets/javascripts')
  env.append_path('app/assets/stylesheets')
  env.append_path('vendor/assets/javascripts')
  Stylus.setup(env)

  # Configure Sinatra
  set :sprockets, env
  set :views, 'app/views'
  set :erb, :escape_html => true
  set :username, ENV["ABBA_USERNAME"] unless ENV["ABBA_USERNAME"].nil?
  set :password, ENV["ABBA_PASSWORD"] unless ENV["ABBA_PASSWORD"].nil?
  set :ssl, true if %w[true TRUE 1 yes YES on ON t T].include? ENV["ABBA_SSL"]
end

run Sinatra::Application
