require_relative './deals_page.rb'
require 'nokogiri'
require 'open-uri'
require 'json'

module Bariga
  module Amazon
    module AgentFaker
      def self.headers
        {
          "USER-AGENT" => "Mozilla/#{rand(5)+1}.0 (#{['Macintosh','Linux'].sample}; Intel Mac OS X 10_#{(10..13).to_a.sample}_5) AppleWebKit/535.36 (KHTML, like Gecko) Chrome/#{(55..66).to_a.sample}.0.3359.181 Safari/537.36"
        }
      end
    end

    class NokogiriProductPage
      def initialize(props)
        @props = props
        @page = Nokogiri::HTML(open(props[:url], AgentFaker.headers))
      end

      def title
        @title ||= @page.css('[id="productTitle"]').first.inner_text.strip
      end

      def price
        @price ||= @page.css('span[id^="priceblock"]').first.inner_text.strip
      rescue
        nil
      end

      def url
        @url ||= @page.css('link[rel="canonical"]').first[:href]
      end

      def update!
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

      def to_h
        {
          title: title,
          images: images,
          url: url
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
        File.open(file_name, 'w+').write(JSON.generate(products: @deals))
        File.close
      end

      private

      def current_page_deals
        product_cards = @page.css(PRODUCT_CARD_CSS)
        product_cards.map do |product_card|
          NokogiriProductPage.new(NokogiriNewArrivalProductCell.new(product_card).to_h).update!
        end
      end

      def next_page_deals
        return [] unless next_page?
        @page = Nokogiri::HTML(open(URI.join(@base_url, @next_page_url), AgentFaker.headers))
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
        @page = Nokogiri::HTML(open(@page_url, AgentFaker.headers))
      end
    end

    class MenNewArrivals < NewArrivals
      PAGE_HOOK = 'link[rel="canonical"][href*="17589461011"]'.freeze

      def initialize
        super
        @page_url = "#{@base_url}/b?node=17589461011&lo=fashion&sort=date-desc-rank"
        @page = Nokogiri::HTML(open(@page_url, AgentFaker.headers))
      end
    end
  end
end
