require_relative './deals_page.rb'
require_relative '../crawler.rb'
require 'nokogiri'
require 'open-uri'
require 'json'
require 'logger'

module Bariga
  module Crawler
    module Amazon
      LOGGER = Logger.new(STDOUT)
      LOGGER.level = Logger::INFO
      class NokogiriProductPage
        def initialize(props)
          @props = props
          @page = AgentFaker.nokogiri_page(props[:url], AgentFaker.headers('referrer' => props[:url]))
        end

        def title
          @title ||= @page.css('[id="productTitle"]').first.inner_text.strip
        rescue
          @props[:title]
        end

        def price
          @price ||= @page.css('span[id^="priceblock"]').first.inner_text.strip
        rescue
          nil
        end

        def url
          @url ||= @page.css('link[rel="canonical"]').first[:href]
        rescue
          @props[:url]
        end

        def update!
          LOGGER.debug("Fetching data for product [#{@props[:title]}]")
          @props = @props.merge(title: title, price: price, url: url)
        end

        def to_h
          @props
        end
      end

      class NokogiriNewArrivalProductCell
        LINK_CSS = 'a[class*="access-detail-page"]'.freeze
        def initialize(card_element)
          @element = card_element
        end

        def images
          @images ||= @element.css('img').map { |img| [img[:src], URI.extract("#{img[:srcset]}")] }.flatten.uniq
        end

        def title
          @title ||= @element.css(LINK_CSS).first[:title]
        end

        def url
          @url ||= @element.css(LINK_CSS).first[:href]
        end

        def price
          currency = @element.css('.sx-price-currency').first.inner_text
          whole = @element.css('.sx-price-whole').first.inner_text
          fractional = @element.css('.sx-price-fractional').first.inner_text
          "#{currency}#{whole}.#{fractional}"
        rescue
          nil
        end

        def to_h
          {
            title: title,
            images: images,
            url: url,
            price: price
          }
        end
      end
      # TodayDealsPage - Today's deals on Amazon
      class NewArrivals < DealsPage
        include BasicPage

        def self.class_info
          {
              name: "#{shop_name} #{product_type} crawler",
              file_pattern: "#{Date.today.strftime("%Y_%m_%d_#{shop_name}_#{product_type.downcase}.json")}"
          }
        end

        def self.shop_name
          'Amazon'
        end

        def self.base_url
          'https://www.amazon.com'
        end

        NEXT_PAGE_BUTTON_TRAIT = { css: 'a[title="Next Page"]', text: 'Next Page' }.freeze
        PRODUCT_CARD_CSS = 'li[id^="result_"]'.freeze

        def initialize
          @base_url = 'https://www.amazon.com/'
          @next_page_url = nil
        end

        def products
          @products = current_page_deals
          @products += next_page_deals while next_page?
          @products
        end

        private

        def current_page_deals
          product_cards = @page.css(PRODUCT_CARD_CSS)
          products_count = product_cards.size
          LOGGER.debug("Found #{products_count} new arrivals on a page")
          product_cards.map.with_index(1) do |product_card, idx|
            LOGGER.debug("Processing element #[#{idx}/#{products_count}]")
            product_hash = NokogiriNewArrivalProductCell.new(product_card).to_h
            product_hash = NokogiriProductPage.new(product_hash).update! if product_hash[:price].nil?
            product_hash
          end
        end

        def next_page_deals
          return [] unless next_page?
          @page = AgentFaker.nokogiri_page(URI.join(@base_url, @next_page_url), AgentFaker.headers('referrer' => @page_url))
          current_page_deals
        end

        def next_page?
          next_page_link = @page.css(NEXT_PAGE_BUTTON_TRAIT[:css])
          @next_page_url = !next_page_link.empty? && next_page_link.first[:href]
          !next_page_link.empty?
        end
      end

      class WomenNewArrivals < NewArrivals
        include BasicCrawler
        PAGE_HOOK = 'link[rel="canonical"][href*="17595940011"]'.freeze

        def self.product_type
          'Women'
        end

        def initialize
          super
          @page_url = "#{@base_url}/b?node=17595940011&lo=fashion&sort=date-desc-rank"
          @page = AgentFaker.nokogiri_page(@page_url, AgentFaker.headers('referrer' => @page_url))
        end
      end

      class MenNewArrivals < NewArrivals
        include BasicCrawler
        PAGE_HOOK = 'link[rel="canonical"][href*="17589461011"]'.freeze

        def self.product_type
          'Men'
        end

        def initialize
          super
          @page_url = "#{@base_url}/b?node=17589461011&lo=fashion&sort=date-desc-rank"
          @page = AgentFaker.nokogiri_page(@page_url, AgentFaker.headers('referrer' => @page_url))
        end
      end
    end
  end
end
