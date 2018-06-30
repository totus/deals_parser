require_relative '../crawler.rb'

module Bariga
  module Crawler
    module TheOutnet
      class Page
        def self.class_info
          {
              name: "#{shop_name} #{product_type} crawler",
              file_pattern: "#{Date.today.strftime("%Y_%m_%d_#{shop_name}_#{product_type.downcase}.json")}"
          }
        end

        def self.shop_name
          'TheOutnet'
        end

        def self.base_url
          'https://www.theoutnet.com'
        end

        def initialize
          @product_props = {
              price: {
                  css: 'span[class*="discounted"][dir="ltr"]',
                  extractor: [:inner_text]
              },
              url: {
                  css: 'a[class="itemLink"]',
                  extractor: [:[], :href]
              },
              title: {
                  css: 'span[class="title"]',
                  extractor: [:inner_text]
              },
              brand: {
                  css: 'span[itemprop="brand"]',
                  extractor: [:inner_text]
              },
              images: {
                  css: 'img[class*="frontImage"]',
                  extractor: [:[], 'data-srcset'.to_sym]
              }
          }
          @page_url = URI.join(self.class.base_url, @rel_url).to_s
          @page_num = 1
          @page = AgentFaker.nokogiri_page(@page_url)
        end

        def products
          @products = current_page_products
          @products += next_page_products while next_page?
          @products
        end

        private

        def current_page_products
          products = @page.css('li[class="item"]')
          products.map do |product_element|
            product = product_details_for(product_element)
            sanitize_product(product)
          end
        end

        def sanitize_product(product_hash)
          product_hash[:url] = URI.join(self.class.base_url, URI.escape(product_hash[:url])) unless product_hash[:url].nil? || product_hash[:url].starts_with?('http')
          product_hash[:images] = URI.extract(product_hash[:images])
          product_hash[:title] = "#{product_hash[:brand]} - #{product_hash[:title]}"
          product_hash[:price] = product_hash[:price].gsub("\r\n",'').gsub(/\s+/,'')
          product_hash
        end

        def product_details_for(element)
          @product_props.each_with_object({}) do |prop, details|
            property = prop.first
            extract_config = prop.last
            details[property] = extract_data(element, extract_config)
          end

        end

        def next_page_products
          return [] unless next_page?
          next_page_url = URI.join(self.class.base_url, "#{@rel_url}?page=#{@page_num+=1}")
          @page = AgentFaker.nokogiri_page(next_page_url)
          current_page_products
        end

        def announced_amount
          @expected_size ||= @page.css('.totalResultsCount').first.text.to_i
        end

        def next_page?
          (announced_amount - @products.size) > 5
        end
      end

      class Hotlist < Page
        include BasicCrawler

        def self.product_type
          'Hotlist'
        end

        def initialize
          @rel_url = '/en-ua/shop/list/the-hotlist'
          super
        end
      end

      class JustIn < Page
        include BasicCrawler

        def self.product_type
          'JustIn'
        end

        def initialize
          @rel_url = '/en-ua/shop/just-in'
          super
        end
      end
    end
  end
end
