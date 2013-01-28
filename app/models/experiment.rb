module Abba
  class Experiment
    include MongoMapper::Document

    key :name
    timestamps!

    has_many :variants, :class => Abba::Variant

    validates_presence_of :name

    def granular_conversion_rate(start_at, end_at, duration = 1.day)
      variants.all.map do |variant|
        {
          :name   => variant.name,
          :values => variant.granular_conversion_rate(start_at, end_at, duration)
        }
      end
    end
  end
end