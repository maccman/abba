namespace :assets do
  task :precompile do
    require 'fileutils'
    require './app'

    FileUtils.mkdir_p(settings.root + '/public/v1')
    File.open(settings.root + '/public/v1/abba.js', 'w+') do |file|
      file.write settings.sprockets['client/index'].to_s
    end
  end
end