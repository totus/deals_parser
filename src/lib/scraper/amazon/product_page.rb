module Bariga
  module Amazon
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
  end
end