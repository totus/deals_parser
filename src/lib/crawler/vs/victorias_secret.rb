require_relative '../crawler.rb'

module Bariga
  module Crawler
    module VictoriasSecret
      class LingerieArrivals
        include BasicCrawler

        def self.class_info
          {
            name: 'Victorias Secret Lingerie New Arrivals crawler',
            file_pattern: "#{Date.today.strftime('%Y_%m_%d_vs_lingerie.json')}"
          }
        end

        def initialize
          @product_props = {
              price: { css: 'p[class*="price"]', extractor: [:inner_text] },
              url: { css: 'a[itemprop="url"]', extractor: [:[], :href] },
              title: { css: 'div[itemprop="name"]', extractor: [:inner_text] }
          }
          @base_url = 'https://www.victoriassecret.com'
          @page_url = "#{@base_url}/lingerie/new-arrivals"
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
          product_hash
        end

        def product_details_for(element)
          @product_props.each_with_object({}) do |prop, details|
            property = prop.first
            extract_config = prop.last
            details[property] = extract_data(element, extract_config[:css], extract_config[:extractor])
          end
        end
      end
    end
  end
end
