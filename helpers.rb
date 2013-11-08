module Helpers
  class Configuration
    def self.mongomapper_config(mongo_config_file)
      config = {
        'production' => {
          'uri' => ENV['MONGOHQ_URL'] || ENV['MONGOLAB_URI']
        },
        'staging' => {
          'uri' => ENV['MONGOHQ_URL'] || ENV['MONGOLAB_URI']
        },
        'development' => {
          'uri' => 'mongodb://localhost:27017/abba'
        }
      }
      if File.file?(mongo_config_file)
        config = YAML.load(ERB.new(File.read(mongo_config_file)).result)
      end
      config
    end
  end
end
