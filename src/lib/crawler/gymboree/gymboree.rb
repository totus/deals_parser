require 'capybara'
require_relative '../crawler.rb'

module Bariga
  module Crawler
    module Gymboree
      class Page
        def self.class_info
          {
              name: "#{shop_name} #{product_type} crawler",
              file_pattern: "#{Date.today.strftime("%Y_%m_%d_#{shop_name}_#{product_type.downcase}.json")}"
          }
        end

        def self.shop_name
          'Gymboree'
        end

        def self.base_url
          'https://www.gymboree.com'
        end

        def initialize(session)
          @session = session
        end

        def products
          scroll_until(announced_amount, 5)
          products_by_js
        end

        private

        def products_by_js
          script = "Array.from(document.querySelectorAll('div[class=\"product-tile\"]')).map(card => {
  product = JSON.parse(card.getAttribute('data-tagdata'))
  return {
    url: product.productURL,
    title:  product.productName,
    images: product.productImage,
    price: '$'.concat(product.price)
  };
})"
          product_list = @session.evaluate_script script
          product_list.map do |product|
            sanitize_product(product)
          end
        end

        def sanitize_product(product_hash)
          # put the sanitization procedures here if needed
          product_hash
        end

        def announced_amount
          @amount ||= @session.evaluate_script("document.querySelector('span[class*=\"items-count\"]').innerText")[/\d+/].to_i
        end

        def scroll_until(amount, deviation = 10)
          while (amount - @session.evaluate_script("document.querySelectorAll('div[class*=\"product-tile\"]').length")).abs > deviation do
            @session.execute_script("document.querySelectorAll('div[class=\"product-tile\"]')[document.querySelectorAll('div[class=\"product-tile\"]').length - 1].scrollIntoView()")
            load_btn = @session.find_all('button[id*="load-more"]')
            load_btn.first.click unless load_btn.empty?
          end
        end
      end

      class FinalSale < Page
        include BasicCrawler

        def self.product_type
          'FinalSale'
        end

        def initialize
          super(Capybara::Session.new(:selenium_chrome_headless))
          @rel_url = '/final-sale'
          @page_url = URI.join(self.class.base_url, @rel_url).to_s
          @session.visit @page_url
        end
      end

      class NewToSale < Page
        include BasicCrawler

        def self.product_type
          'NewToSale'
        end

        def initialize
          super(Capybara::Session.new(:selenium_chrome_headless))
          @rel_url = '/new-to-sale'
          @page_url = URI.join(self.class.base_url, @rel_url).to_s
          @session.visit @page_url
        end
      end
    end
  end
end
