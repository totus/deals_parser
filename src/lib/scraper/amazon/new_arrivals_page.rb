require_relative './deals_page.rb'
require 'nokogiri'
require 'open-uri'
require 'json'
require 'logger'

module Bariga
  module Amazon
    LOGGER = Logger.new(STDOUT)
    module AgentFaker
      def self.headers
        {
          'User-Agent' => "Mozilla/#{rand(5)+1}.0 (#{['Macintosh','Linux', 'Windows'].sample}; Intel Mac OS X 10_#{(10..13).to_a.sample}_5) #{['AppleWebKit', 'Opera', 'Safari', 'Chrome']}/535.36 (KHTML, like Gecko) Chrome/#{(55..66).to_a.sample}.0.3359.181 Safari/537.36",
          'accept-language' => 'en-US,en;q=0.9,ru;q=0.8',
          'accept' => 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8'
        }
      end
    end

    class NokogiriProductPage
      def initialize(props)
        @props = props
        @page = Nokogiri::HTML(open(props[:url], AgentFaker.headers.merge('referrer' => @props[:url])))
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


      NEXT_PAGE_BUTTON_TRAIT = { css: 'a[title="Next Page"]', text: 'Next Page' }.freeze
      PRODUCT_CARD_CSS = 'li[id^="result_"]'.freeze

      def initialize
        @base_url = 'https://www.amazon.com/'
        @next_page_url = nil
      end

      def deals
        @deals = current_page_deals
        @deals += next_page_deals while next_page?
        @deals
      end

      def save_deals(file_name = nil)
        file_name ||= "#{Date.today.strftime('%Y_%m_%d')}#{self.class.name}.json"
        File.open(file_name, 'w+').write(JSON.generate(size: @deals.size, products: @deals))
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
        @page = Nokogiri::HTML(open(URI.join(@base_url, @next_page_url), AgentFaker.headers.merge('referrer' => @page_url)))
        current_page_deals
      end

      def next_page?
        next_page_link = @page.css(NEXT_PAGE_BUTTON_TRAIT[:css])
        @next_page_url = !next_page_link.empty? && next_page_link.first[:href]
        !next_page_link.empty?
      end
    end

    class WomenNewArrivals < NewArrivals
      PAGE_HOOK = 'link[rel="canonical"][href*="17595940011"]'.freeze

      def initialize
        super
        @page_url = "#{@base_url}/b?node=17595940011&lo=fashion&sort=date-desc-rank"
        @page = Nokogiri::HTML(open(@page_url, AgentFaker.headers.merge('referrer' => @page_url)))
      end
    end

    class MenNewArrivals < NewArrivals
      PAGE_HOOK = 'link[rel="canonical"][href*="17589461011"]'.freeze

      def initialize
        super
        @page_url = "#{@base_url}/b?node=17589461011&lo=fashion&sort=date-desc-rank"
        @page = Nokogiri::HTML(open(@page_url, AgentFaker.headers.merge('referrer' => @page_url)))
      end
    end
  end
end
