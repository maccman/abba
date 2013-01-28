module Abba
  class Variant
    include MongoMapper::Document
    CONTROL = '_control'

    key :name

    timestamps!

    many :started_requests, :as => :started_request, :class => Abba::Request
    many :completed_requests, :as => :completed_request, :class => Abba::Request

    validates_presence_of :name

    belongs_to :experiment, :class => Abba::Experiment

    scope :control, where(:name => CONTROL)

    def control?
      name == CONTROL
    end

    def full_name
      control? ? 'Control' : name
    end

    def start!(request)
      self.started_requests.create!(:request => request)
    end

    def complete!(request)
      self.completed_requests.create!(:request => request)
    end

    def conversion_rate_for(options = {})
      VariantPresentor.new(self, nil, options).conversion_rate
    end

    def granular_conversion_rate(options = {})
      duration = options[:duration] || 1.day
      start_at = options[:start_at] || 7.days.ago
      end_at   = options[:end_at]   || Time.now
      results  = []

      while start_at < end_at
        rate = conversion_rate_for(
          options.merge(start_at: start_at, end_at: start_at + duration)
        )
        results << {:time => start_at, :rate => rate}
        start_at += duration
      end

      results
    end
  end
end