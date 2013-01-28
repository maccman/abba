module Abba
  class Experiment
    include MongoMapper::Document

    key :name
    timestamps!

    has_many :variants, :class => Abba::Variant

    validates_presence_of :name

    def granular_conversion_rate(options = {})
      variants.all.map do |variant|
        {
          :name   => variant.full_name,
          :values => variant.granular_conversion_rate(options)
        }
      end
    end

    def control
      self.variants.control.first
    end

    def as_json(options = nil)
      {id: id, name: name}
    end
  end
end