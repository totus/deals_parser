require_relative '../crawler.rb'

module Bariga
  module Crawler
    module Asos
      class DesignerSales
        def self.class_info
          {
              name: "ASOS #{product_type} Designer Brands crawler",
              file_pattern: "#{Date.today.strftime("%Y_%m_%d_#{shop_name}_#{product_type.downcase}.json")}"
          }
        end

        def self.shop_name
          'ASOS'
        end

        def self.base_url
          'https://www.asos.com'
        end

        def initialize(crawl_from_json = true)
          @product_props = {
              price: {
                  css: 'span[data-auto-id="productTileSaleAmount"]',
                  extractor: [:inner_text]
              },
              url: {
                  css: 'a',
                  extractor: [:[], :href]
              },
              title: {
                  css: 'div[data-auto-id="productTileDescription"]',
                  extractor: [:inner_text]
              },
              images: {
                  css: 'img[data-auto-id="productTileImage"]',
                  extractor: [:[], :src],
                  skip: [:nil?],
                  fallbacks: [{ css: 'img[srcset]',
                                extractor: [:[], :srcset] }]
              }
          }
          @page = AgentFaker.nokogiri_page(@page_url)
          @crawl_type = crawl_from_json ? :json : :html
        end

        def products
          @products = current_page_products
          @products += next_page_products while next_page?
          @products
        end

        private

        def current_page_products
          send("products_data_from_#{@crawl_type}".to_sym)
        end

        def products_data_from_html
          products = @page.css('article')
          products.map do |product|
            product_details_for(product)
          end
        end

        def products_data_from_json
          script_element = @page.css('script').find { |script| script.inner_text.start_with?('window.__asos_plp_.data') }
          page_data = JSON.parse(script_element.inner_text.gsub(/^window\.__asos_plp_\.data=/, '').gsub(/;$/, ''))
          products = page_data['search']['products']
          products.map do |product|
            product_data_from_hash(product)
          end
        end

        def product_data_from_hash(hash)
          {
            title: hash['description'],
            price: hash['reducedAmount'] || hash['amount'],
            url: absolutize_url(hash['url']),
            images: absolutize_url(hash['image'])
          }
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

        def product_details_for(element)
          @product_props.each_with_object({}) do |prop, details|
            property = prop.first
            extract_config = prop.last
            details[property] = extract_data(element, extract_config)
          end
        end
      end

      class Women < DesignerSales
        include BasicCrawler

        def self.product_type
          'Women'
        end

        def initialize
          @page_url = "#{self.class.base_url}/women/sale/designer-brands/cat/?cid=11625"
          super
        end
      end

      class Men < DesignerSales
        include BasicCrawler

        def self.product_type
          'Men'
        end

        def initialize
          @page_url = "#{self.class.base_url}/men/sale/cat/?cid=8409"
          super
        end
      end
    end
  end
end