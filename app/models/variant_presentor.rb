module Abba
  class VariantPresentor
    class Group
      attr_reader :experiment, :options, :variants, :control

      def initialize(experiment, options = {})
        @experiment = experiment
        @options    = options
        @control    = experiment.control
        @control    = VariantPresentor.new(control, nil, options) if control
        @variants   = experiment.variants
      end

      def to_a
        result = @variants.map do |variant|
          VariantPresentor.new(variant, control, options)
        end

        result.sort_by(&:conversion_rate).reverse
      end

      def each(&block)
        to_a.each(&block)
      end
    end

    attr_reader :variant, :control, :options

    def initialize(variant, control = nil, options = {})
      @variant = variant
      @control = control
      @options = options
    end

    def started_count
      @started_count ||= started_requests.count
    end

    def completed_count
      @completed_count ||= completed_requests.count
    end

    def conversion_rate
      return 0 if started_count.zero?
      (completed_count.to_f / started_count.to_f)
    end

    def percent_conversion_rate
      (conversion_rate * 100).round(1)
    end

    def probability
      return unless completed_count >= 25

      score = z_score.try(:abs)
      return unless score

      probability = Z_TO_PROBABILITY.find { |z,p| score >= z }
      probability ? probability.last : 0
    end

    def percent_difference
      return if control? || !control
      return 0 if control.conversion_rate.zero?

      rate = (conversion_rate - control.conversion_rate) / control.conversion_rate
      (rate * 100).round(1)
    end

    def id
      variant.id
    end

    def name
      variant.name
    end

    def control?
      variant.control?
    end

    protected

    def started_requests
      query = variant.started_requests

      if options[:start_at] && options[:end_at]
        query = query.for_period(options[:start_at], options[:end_at])
      end

      if options[:tranche]
        query = query.tranche(options[:tranche])
      end

      query
    end

    def completed_requests
      query = variant.completed_requests

      if options[:start_at] && options[:end_at]
        query = query.for_period(options[:start_at], options[:end_at])
      end

      if options[:tranche]
        query = query.tranche(options[:tranche])
      end

      query
    end

    def z_score
      return if control? || !control

      pc = control.conversion_rate
      nc = control.started_count
      p  = conversion_rate
      n  = started_count

      return if nc.zero? || n.zero?

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