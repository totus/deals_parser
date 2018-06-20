require 'nokogiri'
require_relative '../crawler.rb'

module Bariga
  module Crawler
    module SixPM
      class Arrivals
        def self.class_info
          {
              name: "6PM#{product_type} Category crawler",
              file_pattern: "#{Date.today.strftime("%Y_%m_%d_6pm_#{product_type.downcase}.json")}"
          }
        end

        def self.base_url
          'https://www.6pm.com'
        end

        def initialize
          @product_props = {
              brand: {
                       css: 'span[class="_2gUhV"]',
                       extractor: [:inner_text]
                     },
              title: {
                  css: 'span[class="_1EacL"]',
                  extractor: [:inner_text]
              },
              price: {
                  css: 'span[class="_2Nb_U"]',
                  extractor: [:inner_text]
              },
              url: {
                  css: 'a[itemprop="url"]',
                  extractor: [:[], :href]
              },
              images: {
                  css: 'img',
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
          products = @page.css('div[itemtype="http://schema.org/Product"]')
          products.map do |product|
            sanitize_product(product_details_for(product))
          end
        end

        def next_page_products
          return [] unless next_page?
          next_page_url = absolutize_url(next_page?)
          @page = AgentFaker.nokogiri_page(next_page_url)
          current_page_products
        end

        def next_page?
          next_page_link = @page.css('link[rel="next"]').first
          next_page_link && next_page_link[:href]
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
      end

      class Men < Arrivals
        include BasicCrawler

        def self.product_type
          'Men'
        end

        def initialize
          @rel_url = 'men/wAEC4gICMBiCAwP3xAE.zso?s=isNew/desc/goLiveDate/desc/recentSalesStyle/desc/'
          super
        end
      end

      class Women < Arrivals
        include BasicCrawler

        def self.product_type
          'Women'
        end

        def initialize
          @rel_url = '/women/wAEB4gICMBiCAwP3xAE.zso?s=isNew/desc/goLiveDate/desc/recentSalesStyle/desc/'
          super
        end
      end
    end
  end
end