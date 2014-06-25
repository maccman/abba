# Number of processes
worker_processes Integer(ENV["WEB_CONCURRENCY"]) || 3

# Time out
timeout 30
