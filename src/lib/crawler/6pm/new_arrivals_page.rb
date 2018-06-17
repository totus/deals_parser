require 'nokogiri'

module Bariga
  module SixPM

    class ProductCell
      def initialize(element)
        @element = element
      end

      def title
        @element.css('div[itemprop="name"]').first.inner_text.strip
      end

      def price
        @element.css('p[class*="price"]').first.inner_text.strip
      end

      def url
        @element.
      end

      def images

      end
    end

    class NewArrivalsPage
      PRODUCT_CARD_CSS = 'li[itemtype="http://schema.org/Product"]'.freeze

      private

      def current_page_deals
        @page.css(PRODUCT_CARD_CSS)
      end
    end
  end
end