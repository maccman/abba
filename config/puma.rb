workers Integer(ENV['WEB_CONCURRENCY'] || 3)

# TODO: Run MongoMapper single-threaded until it's confirmed to be threadsafe
threads_count = Integer(ENV['MAX_THREADS'] || 1)
threads threads_count, threads_count

preload_app!

rackup      DefaultRackup
environment ENV['RACK_ENV'] || 'development'
if ENV['BOXEN_SOCKET_DIR']
  bind "unix://#{ENV['BOXEN_SOCKET_DIR']}/abba"
else
  port ENV['PORT'] || 5000
end

on_worker_boot do
  # TODO: Disconnect MongoMapper/Mongo::Client connection
end
