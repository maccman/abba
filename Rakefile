namespace :assets do
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
