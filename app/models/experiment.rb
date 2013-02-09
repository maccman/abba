module Abba
  class Experiment
    include MongoMapper::Document

    key :name
    key :running, Boolean, :default => true
    timestamps!

    has_many :variants, :class => Abba::Variant, :dependent => :destroy

    validates_presence_of :name

    def granular_conversion_rate(options = {})
      variants.all.map do |variant|
        {
          :name   => variant.name,
          :values => variant.granular_conversion_rate(options)
        }
      end
    end

    def control
      variants.control.first
    end

    def started_count
      variants.sum(&:started_count)
    end

    def completed_count
      variants.sum(&:completed_count)
    end

    def as_json(options = nil)
      {id: id, name: name}
    end
  end
end