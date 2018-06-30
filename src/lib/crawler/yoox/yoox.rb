require_relative '../crawler.rb'

module Bariga
  module Crawler
    module Yoox
      class Page
        def self.class_info
          {
              name: "#{shop_name} #{product_type} crawler",
              file_pattern: "#{Date.today.strftime("%Y_%m_%d_#{shop_name}_#{product_type.downcase}.json")}"
          }
        end

        def self.shop_name
          'Yoox'
        end

        def self.base_url
          'https://www.yoox.com'
        end

        def initialize
          @product_props = {
              price: {
                  css: 'span[class*="fullprice"]',
                  extractor: [:inner_text]
              },
              url: {
                  css: 'a[class="itemlink"]',
                  extractor: [:[], :href]
              },
              title: {
                  css: 'span[class$="microcategory"]',
                  extractor: [:inner_text]
              },
              brand: {
                  css: 'span[class$="brand"]',
                  extractor: [:inner_text]
              },
              images: {
                  css: 'img[class*="imgFormat_20_f"]',
                  extractor: [:[], :src]
              }
          }
          @page_url = URI.join(self.class.base_url, URI.escape(@rel_url)).to_s
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
          products = @page.css('div[class*="itemContainer"]')
          products.map do |product_element|
            product = product_details_for(product_element)
            next if product[:url].nil?
            sanitize_product(product)
          end.compact
        end

        def sanitize_product(product_hash)
          product_hash[:url] = URI.join(self.class.base_url, URI.escape(product_hash[:url])) unless product_hash[:url].nil? || product_hash[:url].starts_with?('http')
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
          next_page_url = URI.join(self.class.base_url, URI.escape("#{@rel_url}/#{@page_num+=1}"))
          @page = AgentFaker.nokogiri_page(next_page_url)
          current_page_products
        end

        def next_page?
          @page.css('a[class*="nextPage"]').first
        end
      end

      class MenNewArrival < Page
        include BasicCrawler

        def self.product_type
          'MenNewArrival'
        end

        def initialize
          @rel_url = '/ua/для мужчин/новые поступления/shoponline'
          super
        end
      end

      class WomenNewArrival < Page
        include BasicCrawler

        def self.product_type
          'WomenNewArrival'
        end

        def initialize
          @rel_url = '/ua/для женщин/новые поступления/shoponline'
          super
        end
      end

      class DesignAndArts < Page
        include BasicCrawler

        def self.product_type
          'Design&Arts'
        end

        def initialize
          @rel_url = '/ua/дизайн+искусство/previewdesign/shoponline'
          super
        end
      end
    end
  end
end
