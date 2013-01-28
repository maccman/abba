require './app'
require './admin'

map '/assets' do
  run Catapult.environment
end

run Sinatra::Application