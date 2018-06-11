require 'uri'
require 'capybara'
require 'json'
require 'logger'

require_relative '../model/good.rb'

# top module for all bariga-related stuff
module Bariga
  LOGGER = Logger.new(STDOUT)
  LOGGER.level = Logger::DEBUG

  # module for dealing with Amazon shit
  module Amazon
    # module with basic functionality of a page (defined by a presence of unique hook selector)
    module BasicPage
      PAGE_HOOK = nil

      def current?
        page_hook = self.class.const_get(:PAGE_HOOK)
        LOGGER.info("Checking URL [#{URI(@session.current_url).path}] for presence of [#{page_hook}]")
        !@session.find_all(page_hook).empty?
      end
    end

    # fucking factory
    class PageFactory
      def initialize(session)
        @session = session
      end

      def identify_page
        nil.nil?
      end
    end

    # Common ancestor for all the Amazon's Deals pages of various types
    class DealsPage
      NEXT_PAGE_BUTTON_SELECTOR = 'a[href="#next"]'.freeze

      def initialize(session)
        @session = session
        @goods = []
      end

      protected

      def parse(use_selector = GoodCell::SELECTOR)
        LOGGER.debug("Started parsing #{@session.current_url}")
        goods = @session.find_all(use_selector)
        parsed = goods.map.with_object([]) do |good_element, res|
          res << GoodCell.new(good_element, @session)
          res.last.collect_data
        end.flatten
        LOGGER.debug("Parsed #{parsed.size} items")
        parsed
      end
    end

    # TodayDealsPage - Today's deals on Amazon
    class TodayDealsPage < DealsPage
      include BasicPage

      PAGE_HOOK = 'link[rel="canonical"][href="https://www.amazon.com/gp/goldbox/"]'.freeze
      SUMMARY_BAR_CSS = 'div[class*="filterSummaryBar"]'.freeze
      COUNT_REGEX = /^[^\d]+\d+(?:-\d+)?(?:\s+\b[^\d]+\b\s+)*(\d+)/

      def initialize(session)
        super(session)
        @base_url = 'https://www.amazon.com/gp/goldbox/'
      end

      def total_deals
        @total_deals ||= @session.find(SUMMARY_BAR_CSS).text[COUNT_REGEX, 1].to_i
      end

      def active_deals
        process_raw(raw_deals.flatten)
      end

      def raw_deals
        @raw_deals ||= fetch_all
      end

      def open
        @session.visit @base_url
        self
      end

      private

      def process_raw(deals)
        counter = 0
        deals.map do |product|
          LOGGER.debug "Opening url #{product}"
          @session.visit product.url
          page = GoodPage.new(@session)
          LOGGER.info "processing element ##{counter += 1}"
          # select_first_interim unless page.current?
          next unless page.current? # TODO: properly process non-single items instead of skipping them
          attributes = page.fetch
          product.to_obj(attributes)
        end.compact
      end

      def fetch_all
        @goods << parse
        @goods << fetch_next while next_page? && @goods.size < total_deals
        LOGGER.info "Parsed and fetched #{@goods.compact!.size} items"
        @goods
      end

      def select_first_interim
        interim_link = (@session.find_all('a[class*="access-detail-page"]').first ||
                        @session.find_all('a[class*="asin-link"]').first ||
                        @session.find_all('div[class*="card-details"]').first.find_all('a').first)
        @session.visit interim_link[:href]
      end

      def fetch_next
        LOGGER.info 'Fetching next page'
        @session.find(NEXT_PAGE_BUTTON_SELECTOR).click
        parse
      end

      def next_page?
        !@session.find_all(NEXT_PAGE_BUTTON_SELECTOR).empty?
      end
    end

    # class describing a dedicated product description page
    class GoodPage
      include BasicPage

      PAGE_HOOK = 'form[id="addToCart"]'.freeze

      def initialize(session)
        @session = session
        @storage = {}
      end

      def url
        LOGGER.debug("Getting canonical URL from [#{URI(@session.current_url).path}]")
        @url ||= @session.find_all('link[rel="canonical"]', visible: false).first[:href].strip
      end

      def product_title
        LOGGER.debug("Getting product title from #{URI(url).path}")
        @session.find_all('span[id*="roductTitle"]').first.text.strip
      end

      def images
        @session.find_all('div[id="main-image-container"] img').map { |img| img[:src] }
      end

      def price
        @session.find_all('.a-color-price').first.text.strip
      end

      def fetch
        @storage.update(title: product_title, images: images, price: price, url: url)
      end
    end

    # class describing PageElement on Today's Deals page with an appropriate product
    class GoodCell
      SELECTOR = 'div[id^="100_dealView_"][class*="singleCell"]'.freeze
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
