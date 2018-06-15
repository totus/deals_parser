require_relative '../support/extensions.rb'

module Bariga
  TEMP = "#{File.expand_path(__dir__)}/../../data/temporary/".freeze
  # mix-in with defined method for images
  module Viewable
    def as_message(max_size = 200)
      LOGGER.debug(["Product is:", "price: #{price}", "url: #{url}", "title: #{title}"].join("\n->"))
      price_and_url = "*#{price}*\n#{url}"
      "*#{price}*\n#{title[0, 100 - price_and_url.length]}\n#{url}\nCall #911"[0, max_size]
    end
  end

  # mix-in with methods for save & load
  module Portable
    def save
      File.open(File.join(TEMP, "#{@raw[:title].hash.to_s(16)}.json"), 'w+').write(JSON.generate(@raw)) unless @raw.empty?
    end
  end

  # Basic entity that describes a product fetched from this or that marketplace
  class Good
    attr_reader :raw
    include Viewable
    include Portable

    def self.from_json(json_data)
      products = JSON.parse(json_data)
      # LOGGER.debug("Loaded #{products}")
      products['products'] ? products['products'].map { |thing| Good.new(thing) } : products
    end

    def method_missing(method, *args, &block)
      @object.respond_to?(method) ? @object.send(method, *args, &block) : super
    end

    def respond_to_missing?(method_name, include_private = false)
      @object.respond_to?(method_name) || super
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
