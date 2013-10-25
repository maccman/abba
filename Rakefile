require 'rubygems'
require 'bundler'

Bundler.require
$: << settings.root

namespace :assets do
  desc "Precompile assets"
  task :precompile do
    require 'fileutils'
    require 'sprockets'
    require 'uglifier'

    sprockets = Sprockets::Environment.new
    sprockets.js_compressor = Uglifier.new
    sprockets.append_path('app/assets/javascripts')

    FileUtils.mkdir_p('public/v1')
    File.open('public/v1/abba.js', 'w+') do |file|
      file.write sprockets['client/index'].to_s
    end
  end
end

namespace :db do
  desc "Create MongoDB indexes"
  task :create_indexes do
    require 'app'
    Abba::Request.ensure_index([[:started_request_type, 1], [:started_request_id, 1], [:created_at, 1], [:browser, 1], [:browser_version, 1]])
    Abba::Request.ensure_index([[:completed_request_type, 1], [:completed_request_id, 1], [:created_at, 1], [:browser, 1], [:browser_version, 1]])
  end
end
