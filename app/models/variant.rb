module Abba
  class Variant
    include MongoMapper::Document

    key :name
    key :started_count, :default => 0
    key :completed_count, :default => 0

    timestamps!

    belongs_to :test, :class => Abba::Test

    validates_presence_of :name

    def start!(env)
      increment :started_count => 1
      # Record browser/time
      # Granularity - day
    end

    def complete!(env)
      increment :completed_count => 1
    end

    def conversion_rate
      return 0 if started_count.zero?
      (completed_count.to_f / started_count.to_f)
    end

    def reset!
      self.started_count   = 0
      self.completed_count = 0
      self.save!
    end
  end
end