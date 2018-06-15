require 'uri'
require 'capybara'
require 'json'
require 'logger'

require_relative '../model/good.rb'
require_relative './basic_page.rb'

# top module for all bariga-related stuff
module Bariga
  LOGGER = Logger.new(STDOUT)
  LOGGER.level = Logger::DEBUG

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

    # class describing a dedicated product description page
    class GoodPage
      include Bariga::BasicPage

      PAGE_HOOK = 'form[id="addToCart"]'.freeze

      def initialize(session)
        @session = session
        @storage = {}
      end

      def url
        LOGGER.debug("Getting canonical URL from [#{URI(@session.current_url).path}]")
        @url ||= @session.find_all('link[rel="canonical"]', visible: false).first[:href].strip
      rescue
        @url ||= @session.current_url[0, @session.current_url.rindex('/')]
      end

      def product_title
        LOGGER.debug("Getting product title from #{URI(url).path}")
        @session.find_all('span[id*="roductTitle"]').first.text.strip
      end

      def images
        @session.find_all('div[id="main-image-container"] img').map { |img| img[:src] }
      end

      def categories
        @categories ||= @session.find('div[class*="breadcrumb"]').find_all('span[class="a-list-item"]').map(&:text)
      rescue
        []
      end

      # TODO: add ASIN scraping from 'https://www.amazon.com/Shade-Side-Rear-Window-Pack/dp/B0104OFF7E'
      def asin
        @asin ||= @session.find_all('table[class*="prodDetTable"]').first.find('tr', text: 'ASIN').text.split.last
      rescue
        asin_container = @session.find_all('div[id*="detail"][id*="ullets"]').first
        @asin ||= asin_container && asin_container.find('li', text: 'ASIN').text.split.last
      rescue
        ''
      end

      def price
        @session.find_all('.a-color-price').first.text.strip
      end

      def fetch
        @storage.update(title: product_title, images: images, price: price, url: url, categories: categories, asin: asin)
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
