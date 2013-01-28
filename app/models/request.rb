module Abba
  class Request
    include MongoMapper::Document

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

    scope :browser, lambda {|browser|
      where(:browser => browser)
    }

    scope :mobile, where(:mobile => true)

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