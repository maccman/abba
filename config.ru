require './app'
require './admin' # TODO

map '/assets' do
  run Catapult.environment
end

run Sinatra::Application