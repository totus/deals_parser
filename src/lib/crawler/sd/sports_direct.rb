require_relative '../crawler.rb'

module Bariga
  module Crawler
    module SportsDirect
      class Page
        def self.class_info
          {
              name: "SportsDirect #{product_type} crawler",
              file_pattern: "#{Date.today.strftime("%Y_%m_%d_#{shop_name}_#{product_type.downcase}.json")}"
          }
        end

        def self.shop_name
          'SportsDirect'
        end

        def self.base_url
          'https://www.sportsdirect.com'
        end

        def initialize
          @product_props = {
              price: {
                  css: 'span[class*="curprice"]',
                  extractor: [:inner_text]
              },
              url: {
                  css: 'a',
                  extractor: [:[], :href]
              },
              title: {
                  css: 'span[class$="name"]',
                  extractor: [:inner_text]
              },
              brand: {
                  css: 'span[class$="brand"]',
                  extractor: [:inner_text]
              },
              img: {
                  css: 'img[class*="MainImage"]',
                  extractor: [:[], :src]
              }
          }
          @page_url = URI.join(self.class.base_url, @rel_url).to_s
          @page = AgentFaker.nokogiri_page(@page_url)
        end

        def products
          @products = current_page_products
          @products += next_page_products while next_page?
          @products
        end

        private

        def current_page_products
          products = @page.css('li[li-productid]')
          products.map do |product|
            sanitize_product(product_details_for(product))
          end
        end

        def sanitize_product(product_hash)
          product_hash[:url] = absolutize_url(product_hash[:url])
          product_hash[:img] = "https:#{product_hash[:img]}" if product_hash[:img].start_with?('//')
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
          next_page_url = absolutize_url(next_page?)
          @page = AgentFaker.nokogiri_page(next_page_url)
          current_page_products
        end

        def next_page?
          next_page_link = @page.css('a[class*="NextLink"]').first
          next_page_link && next_page_link[:href]
        end
      end

      class WeeklyOffer < Page
        include BasicCrawler

        def self.product_type
          'WeeklyOffer'
        end

        def initialize
          @rel_url = '/weekly-offer'
          super
        end
      end
    end
  end
end
