require_relative '../crawler.rb'

module Bariga
  module Crawler
    module VictoriasSecret
      class Arrivals
        def self.class_info
          {
            name: "Victorias Secret #{product_type} New Arrivals crawler",
            file_pattern: "#{Date.today.strftime("%Y_%m_%d_vs_#{product_type.downcase}.json")}"
          }
        end

        def self.base_url
          'https://www.victoriassecret.com'
        end

        def initialize
          @product_props = {
              price: {
                       css: 'p[class*="price"]',
                       extractor: [:inner_text]
                     },
              url: {
                     css: 'a[itemprop="url"]',
                     extractor: [:[], :href]
                   },
              title: {
                       css: 'div[itemprop="name"]',
                       extractor: [:inner_text]
                     },
              img: {
                     css: 'img[role*="presentation"]',
                     extractor: [:[], :src],
                     skip: [:nil?, [:end_with?, 'white.png']],
                     fallbacks: [{css: 'meta[itemprop="image"]',
                                  extractor: [:[], :content]}]
                   }
          }
          @page = AgentFaker.nokogiri_page(@page_url)
        end

        def products
          products = @page.css('li[itemtype="http://schema.org/Product"]')
          products.map do |product|
            sanitize_product(product_details_for(product))
          end
        end

        private

        def sanitize_product(product_hash)
          product_hash[:url] = absolutize_url(product_hash[:url])
          product_hash[:title] = product_hash[:title].gsub(/^New!\s*/i, '')
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
      # Class to fetch data from Lingerie arrivals
      class Lingerie < Arrivals
        include BasicCrawler

        def self.product_type
          'Lingerie'
        end

        def initialize
          @page_url = "#{self.class.base_url}/lingerie/new-arrivals"
          super
        end
      end

      class Sports < Arrivals
        include BasicCrawler

        def self.product_type
          'Sports'
        end

        def initialize
          @page_url = "#{self.class.base_url}/vs-sport/new-arrivals"
          super
        end
      end

      class Sleepwear < Arrivals
        include BasicCrawler

        def self.product_type
          'sleepwear'
        end

        def initialize
          @page_url = "#{self.class.base_url}/sleepwear/new-arrivals"
          super
        end
      end

      class PinkSale < Arrivals
        include BasicCrawler

        def self.product_type
          'all_pink'
        end

        def initialize
          @page_url = "#{self.class.base_url}/pink/sale-all-pink"
          super
        end
      end
    end
  end
end
