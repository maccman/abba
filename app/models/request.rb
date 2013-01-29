module Abba
  class Request
    include MongoMapper::Document

    TRANCHES = {
      chrome:  {browser: 'Chrome'},
      safari:  {browser: 'Safari'},
      firefox: {browser: 'Firefox'},
      ie:      {browser: 'Internet Explorer'},
      ie6:     {browser: 'Internet Explorer', browser_version: '6.0'},
      ie7:     {browser: 'Internet Explorer', browser_version: '7.0'},
      ie8:     {browser: 'Internet Explorer', browser_version: '8.0'},
      ie9:     {browser: 'Internet Explorer', browser_version: '9.0'},
      ie10:    {browser: 'Internet Explorer', browser_version: '10.0'},
      mobile:  {mobile: true}
    }

    key :url
    key :ip
    key :user_agent
    key :browser
    key :browser_version
    key :platform
    key :mobile, Boolean

    belongs_to :started_request, :polymorphic => true
    belongs_to :completed_request, :polymorphic => true

    timestamps!

    scope :for_period, lambda {|start_at, end_at|
      where(:created_at => {:$gt => start_at, :$lt => end_at})
    }

    scope :tranche, lambda {|name|
      where(TRANCHES[name] || {})
    }

    def request=(request)
      self.url             = request.referrer
      self.ip              = request.ip
      self.user_agent      = request.user_agent

      self.browser         = parsed_user_agent.browser
      self.browser_version = parsed_user_agent.version.to_s
      self.platform        = parsed_user_agent.platform
      self.mobile          = parsed_user_agent.mobile?

      self
    end

    def parsed_user_agent
      @parsed_user_agent ||= UserAgent.parse(user_agent)
    end
  end
end