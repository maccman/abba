module Abba
  class Test
    include MongoMapper::Document

    key :name
    timestamps!

    has_many :variants, :class => Abba::Variant

    validates_presence_of :name
  end
end