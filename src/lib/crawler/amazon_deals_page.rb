require 'uri'
require 'capybara'
require 'json'
require 'logger'

require_relative '../model/good.rb'
require_relative './basic_page.rb'

# top module for all bariga-related stuff
module Bariga
  LOGGER = Logger.new(STDOUT)
  LOGGER.level = Logger::INFO

  # module for dealing with Amazon shit
  module Amazon
    # fucking factory
    class PageFactory
      def initialize(session)
        @session = session
      end

      def identify_page
        nil.nil?
      end
    end

    # class describing PageElement on Today's Deals page with an appropriate product
    class GoodCell
      # TODO: Whenever parsing returns zero elements, we need to indicate it and adjust the code/selectors
      SELECTOR = 'div[id*="_dealView_"][class*="singleCell"]'.freeze
      def initialize(good_element, session)
        @element_card = good_element
        @session = session
        @storage = {}
      end

      def images
        @element_card.find_all('img').map { |img| img.send(:[], :src) }
      end

      def price
        @element_card.find('div[class*="priceBlock"]').text
      rescue RuntimeError, Capybara::ElementNotFound
        0
      end

      def collect_data
        @storage = { images: images,
                     price: price,
                     start_date: start_date,
                     end_date: end_date,
                     url: url }
      end

      def product_name!
        @session.visit url
        @url = @session.find('link[rel="canonical"]').href
        @session.find('div[id="productTitle"]').text.strip
      end

      def product_name
        @product_name ||= product_name!
      end

      def url
        @url ||= @element_card.find('a[id="dealTitle"]')[:href]
      end

      def availability
        nil
      end

      def active?
        Time.now.between?(start_date, end_date)
      end

      def start_date
        Time.now - 1 # TODO: should be replaced with appropriate extraction from site source
      end

      def end_date
        Time.now + 3 # TODO: should be replaced with appropriate extraction from site source
      end

      def to_obj(added_attributes)
        LOGGER.debug 'Converting item to a good'
        Bariga::Good.new(@storage.update(added_attributes))
      end

      def to_s
        JSON.generate(@storage)
      end
    end
  end
end
