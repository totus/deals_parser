require_relative '../support/extensions.rb'

module Bariga
  # mix-in with defined method for images
  module Viewable
    def as_message(max_size = 200)
      price_and_url = "*#{price}*\n#{url}"
      "*#{price}*\n#{title[0, 100 - price_and_url.length]}\n#{url}\nCall #911"[0, max_size]
    end
  end

  # Basic entity that describes a product fetched from this or that marketplace
  class Good
    attr_reader :raw
    include Viewable

    def self.from_json(json_data)
      products = JSON.load(json_data)
      # LOGGER.debug("Loaded #{products}")
      products["products"].map { |thing| Good.new(thing) }
    end

    def method_missing(method, *args, &block)
      @object.send(method, *args, &block) if @object.respond_to? method
    end

    def initialize(props)
      @raw = props
      @object = @raw.to_obj
    end

    def single_price?
      price !~ price_separator
    end

    def price_range
      split_price = price.split(price_separator)
      @price_range = split_price.first..split_price.last
    end

    def price_min
      price_range.min
    end

    def price_max
      price_range.max
    end

    def to_s
      JSON.generate(@raw)
    end

    private

    def price_separator
      /\s*-\s*/
    end
  end
end
