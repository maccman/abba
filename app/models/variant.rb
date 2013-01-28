module Abba
  class Variant
    include MongoMapper::Document
    CONTROL = '_control'

    key :name
    key :started_count, :default => 0
    key :completed_count, :default => 0

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

    def percent_conversion_rate
      (conversion_rate * 100).round(1)
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

    # Calculations

    def probability
      score = z_score.try(:abs)
      return unless score
      probability = Z_TO_PROBABILITY.find { |z,p| score >= z }
      probability ? probability.last : 0
    end

    def percent_difference
      control = experiment.control

      return if !control or control == self
      return 0 if control.conversion_rate.zero?

      rate = (conversion_rate - control.conversion_rate) / control.conversion_rate
      (rate * 100).round(1)
    end

    protected

    def z_score
      control = experiment.control
      alt     = self

      return if !control or control == alt

      pc = control.conversion_rate
      nc = control.started_count
      p  = alt.conversion_rate
      n  = alt.started_count

      (p - pc) / ((p * (1-p)/n) + (pc * (1-pc)/nc)).abs ** 0.5
    end

    begin
      a         = 50.0
      norm_dist = []
      (0.0..3.1).step(0.01) { |x| norm_dist << [x, a += 1 / Math.sqrt(2 * Math::PI) * Math::E ** (-x ** 2 / 2)] }
      Z_TO_PROBABILITY = [90, 95, 99, 99.9].map { |pct| [norm_dist.find { |x,a| a >= pct }.first, pct] }.reverse
    end
  end
end