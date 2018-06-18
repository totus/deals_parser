require 'capybara'
require_relative '../crawler.rb'

module Bariga
  module Crawler
    module Disney
      class Page
        def self.class_info
          {
              name: "#{shop_name} #{product_type} crawler",
              file_pattern: "#{Date.today.strftime("%Y_%m_%d_#{shop_name}_#{product_type.downcase}.json")}"
          }
        end

        def self.shop_name
          'Disney'
        end

        def self.base_url
          'https://www.shopdisney.com'
        end

        def initialize(session)
          @session = session
        end

        def products
          scroll_until(announced_amount, 15)
          products_by_js
        end

        private

        def products_by_js
          script = "Array.from(document.querySelectorAll('div[data-entity-type=\"OtiDisneyStoreProduct\"]')).map(card => {
  return {
    url: card.querySelector('a').href,
    title:  card.querySelector('div[class=\"title\"]').innerText,
    images: card.querySelector('div[class=\"bg-image\"]').style.backgroundImage,
    price: card.querySelector('span[class*=\"listprice\"]').innerText
  };
})"
          product_list = @session.evaluate_script script
          product_list.map do |product|
            sanitize_product(product)
          end
        end

        def sanitize_product(product_hash)
          product_hash['images'] = URI.extract(product_hash['images'])
          product_hash
        end

        def announced_amount
          @amount ||= @session.evaluate_script("document.querySelector('span[class*=\"select2-selection__rendered\"]').innerText")[/\d+/].to_i
        end

        def scroll_until(amount, deviation = 10)
          @session.execute_script('window.scrollBy(0, 1000)') while (amount - @session.evaluate_script("document.querySelectorAll('div[class*=\"item-container\"]').length")).abs > deviation
        end
      end

      class NewArrival < Page
        include BasicCrawler

        def self.product_type
          'NewArrival'
        end

        def initialize
          super(Capybara::Session.new(:selenium_chrome_headless))
          @rel_url = '/new'
          @page_url = URI.join(self.class.base_url, @rel_url).to_s
          @session.visit @page_url
        end
      end

      class Sale < Page
        include BasicCrawler

        def self.product_type
          'Sale'
        end

        def initialize
          super(Capybara::Session.new(:selenium_chrome_headless))
          @rel_url = '/sale'
          @page_url = URI.join(self.class.base_url, @rel_url).to_s
          @session.visit @page_url
        end
      end
    end
  end
end
