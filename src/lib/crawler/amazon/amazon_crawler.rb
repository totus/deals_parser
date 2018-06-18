require 'capybara'
require_relative '../crawler.rb'

module Bariga
  module Crawler
    module Amazon
      class AmazonCrawler
        NEXT_PAGE_BUTTON_TRAIT = { css: 'a[href="#next"]', text: 'Next' }.freeze

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

        def initialize(session)
          @session = session
        end

        def products
          @products = products_by_js
          @products += fetch_next while next_page?
          @products
        end

        private

        def products_by_js
          script = "Array.from(document.querySelectorAll('div[id*=\"_dealView_\"][class*=\"singleCell\"]')).map(card => {
return {
  url: card.querySelector('a[id=\"dealTitle\"]') && card.querySelector('a[id=\"dealTitle\"]').href,
  title:  card.querySelector('a[id=\"dealTitle\"]') && card.querySelector('a[id=\"dealTitle\"]').innerText,
  images: Array.from(card.querySelectorAll('img')).map(image => { return image.src; }),
  price: card.querySelector('div[class*=\"priceBlock\"]') ? card.querySelector('div[class*=\"priceBlock\"]').innerText : null
};
})"
          @session.find_all('div[id*="_dealView_"][class*="singleCell"]')
          product_list = @session.evaluate_script(script)
          product_list.first(deals_on_page).uniq
        rescue
          []
        end

        def deals_on_page
          24
        end

        def fetch_next
          @session.find(NEXT_PAGE_BUTTON_TRAIT[:css], text: NEXT_PAGE_BUTTON_TRAIT[:text]).click
          @session.find_all('div[id*="_dealView_"][class*="singleCell"]')
          sleep 2
          products_by_js
        end

        def next_page?
          !@session.find_all(NEXT_PAGE_BUTTON_TRAIT[:css], text: NEXT_PAGE_BUTTON_TRAIT[:text]).empty?
        end
      end

      class TodaysDeals < AmazonCrawler
        include BasicCrawler

        def self.product_type
          'TodaysDeals'
        end

        def initialize
          @page_num = 0
          super(Capybara::Session.new(:selenium_chrome_headless))
          @rel_url = '/gp/goldbox/'
          @page_url = URI.join(self.class.base_url, @rel_url).to_s
          @session.visit @page_url
        end
      end
    end
  end
end