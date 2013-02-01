module Abba
  class Variant
    include MongoMapper::Document

    key :name
    key :control, Boolean, :default => false
    key :started_count, Integer, :default => 0
    key :completed_count, Integer, :default => 0

    timestamps!

    has_many :started_requests, :as => :started_request, :class => Abba::Request, :dependent => :destroy
    has_many :completed_requests, :as => :completed_request, :class => Abba::Request, :dependent => :destroy

    validates_presence_of :name

    belongs_to :experiment, :class => Abba::Experiment

    scope :control, where(:control => true)

    def start!(request)
      self.increment(:started_count => 1)
      self.started_requests.create!(:request => request)
    end

    def complete!(request)
      self.increment(:completed_count => 1)
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