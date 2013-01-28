module Abba
  class Guard
    def initialize(app)
      @app = app
    end

    def call(env)
      unless production?
        return @app.call(env)
      end

      request = Rack::Request.new(env)

      # IP Auth
      if settings.allowed_ips? && settings.allowed_ips.include?(request.ip)
        return @app.call(env)
      end

      # Basic Auth
      if settings.username?
        guard = proc do |username, password|
          username == settings.username && password == settings.password
        end

        basic = Rack::Auth::Basic.new(@app, nil, &guard)
        return basic.call(env)
      end

      @app.call(env)
    end
  end
end