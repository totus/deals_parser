require_relative '../crawler.rb'

module Bariga
  module Crawler
    module VictoriasSecret
      class Page
        def self.class_info
          {
            name: "#{shop_name} #{product_type} crawler",
            file_pattern: "#{Date.today.strftime("%Y_%m_%d_vs_#{product_type.downcase}.json")}"
          }
        end

        def self.base_url
          'https://www.victoriassecret.com'
        end

        def self.shop_name
          'VictoriasSecret'
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
              images: {
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
          product_hash[:images] = "https:#{product_hash[:images]}" if product_hash[:images].start_with?('//')
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
      class LingerieArrivals < Page
        include BasicCrawler

        def self.product_type
          'Lingerie'
        end

        def initialize
          @page_url = "#{self.class.base_url}/lingerie/new-arrivals"
          super
        end
      end

      class SportsArrivals < Page
        include BasicCrawler

        def self.product_type
          'Sports'
        end

        def initialize
          @page_url = "#{self.class.base_url}/vs-sport/new-arrivals"
          super
        end
      end

      class SleepwearArrivals < Page
        include BasicCrawler

        def self.product_type
          'sleepwear'
        end

        def initialize
          @page_url = "#{self.class.base_url}/sleepwear/new-arrivals"
          super
        end
      end

      class PinkSale < Page
        # include BasicCrawler

        def self.product_type
          'all_pink'
        end

        def initialize
          @page_url = "#{self.class.base_url}/pink/sale-all-pink"
          super
        end
      end

      class LingerieSale < Page
        include BasicCrawler

        def self.product_type
          'ClearanceBras'
        end

        def initialize
          @page_url = "#{self.class.base_url}/clearance/lingerie"
          super
        end
      end


      class ClearanceBras < Page
        include BasicCrawler

        def self.product_type
          'ClearanceBras'
        end

        def initialize
          @page_url = "#{self.class.base_url}/sale/clearance-bras"
          super
        end
      end

      class ClearancePanties < Page
        include BasicCrawler

        def self.product_type
          'ClearancePanties'
        end

        def initialize
          @page_url = "#{self.class.base_url}/sale/clearance-panties"
          super
        end
      end

      class ClearanceSport < Page
        include BasicCrawler

        def self.product_type
          'ClearanceSport'
        end

        def initialize
          @page_url = "#{self.class.base_url}/clearance/victorias-secret-sport"
          super
        end
      end

      class BeautyAndAccessories < Page
        include BasicCrawler

        def self.product_type
          'BeautyAndAccessories'
        end

        def initialize
          @page_url = "#{self.class.base_url}/clearance/beautyandaccessories"
          super
        end
      end

      class Accessories < Page
        include BasicCrawler

        def self.product_type
          'Accessories'
        end

        def initialize
          @page_url = "#{self.class.base_url}/clearance/accessories"
          super
        end
      end

      class PinkMLB < Page
        include BasicCrawler

        def self.product_type
          'PinkMLB'
        end

        def initialize
          @page_url = "#{self.class.base_url}/sale/clearance-pink-mlb-collection"
          super
        end
      end

      class PinkPCC < Page
        include BasicCrawler

        def self.product_type
          'PinkPCC'
        end

        def initialize
          @page_url = "#{self.class.base_url}/sale/clearance-pink-collegiate-collection"
          super
        end
      end

      class PinkClearance < Page
        include BasicCrawler

        def self.product_type
          'PinkClearance'
        end

        def initialize
          @page_url = "#{self.class.base_url}/clearance/pink"
          super
        end
      end

      class PinkSwim < Page
        include BasicCrawler

        def self.product_type
          'PinkSwim'
        end

        def initialize
          @page_url = "#{self.class.base_url}/clearance/pink-swim"
          super
        end
      end
    end
  end
end
