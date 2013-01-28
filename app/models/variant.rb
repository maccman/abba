module Abba
  class Variant
    include MongoMapper::Document

    key :name
    key :started_count, :default => 0
    key :completed_count, :default => 0

    timestamps!

    many :started_requests, :as => :started_request, :class => Abba::Request
    many :completed_requests, :as => :completed_request, :class => Abba::Request

    validates_presence_of :name

    def start!(request)
      increment :started_count => 1
      self.started_requests.create!(:request => request)
    end

    def complete!(request)
      increment :completed_count => 1
      self.completed_requests.create!(:request => request)
    end

    def conversion_rate
      return 0 if started_count.zero?
      (completed_count.to_f / started_count.to_f)
    end

    def conversion_rate_for(start_at, end_at)
      started   = started_requests.for_period(start_at, end_at)
      completed = completed_requests.for_period(start_at, end_at)

      return 0 if started.count.zero?
      (completed.count.to_f / started.count.to_f)
    end

    def granular_conversion_rate(start_at, end_at, duration = 1.day)
      results = []

      while start_at < end_at
        rate = conversion_rate_for(start_at, start_at + duration)
        results << {:time => start_at, :rate => rate}
        start_at += duration
      end

      results
    end

    def reset!
      self.started_count   = 0
      self.completed_count = 0
      self.save!
    end

    def as_json(options = {})
      {name: name}
    end
  end
end