require 'nokogiri'
require 'open-uri'
require 'json'
require 'sqlite3'
require_relative '../model/product.rb'

module URI
  class HTTPS
    alias_method :to_str, :to_s
  end
end

module Bariga
  module Crawler
    # mix-in with some crawler common functionality
    module BasicCrawler
      def absolutize_url(url)
        url = sanitize_url(url)
        URI.parse(url).scheme.eql?('https') ? url : URI.join(self.class.base_url, url).to_s
      end

      def sanitize_url(url)
        url = url.gsub(/[\u0080-\u00ff]/, '')
        parsed_url = URI.parse(url)
        truncate_query(parsed_url) unless parsed_url.query.nil?
        parsed_url.to_s
      end

      def extract_data(element, extract_config)
        selector = extract_config[:css]
        extractor_fn = extract_config[:extractor]
        skip_conditions = extract_config[:skip]
        fallbacks = extract_config[:fallbacks]
        res = extract(element, selector, extractor_fn)
        skip_conditions && skip_conditions.any? { |skip| res.send(*skip) } && fallbacks && fallbacks.each do |fallback|
          res = extract(element, fallback[:css], fallback[:extractor])
          break if res
        end
        res
      end

      def self.included(klass)
        Registry.register(klass)
      end

      def save(data)
        persist_data = { products: data, size: data.size }
        File.open(self.class.class_info[:file_pattern], 'w+').write(JSON.generate(persist_data))
      end

      def save_to_db(data)
        data = data.map(&:symbolize_keys)
        successful_results = 0
        incomplete_results = 0
        data.each do |product|
          if incomplete?(product)
            incomplete_results += 1
            next
          end
          imgs = [product[:images]].flatten.map do |image|
            next if image.nil? || image.empty?
            Image.find_by(url: image) || Image.create(url: image)
          end.compact
          prod = Product.find_by(url: product[:url])
          if prod
            prod.update(name: product[:title], url: product[:url], price: product[:price])
            prod.save
          else
            prod = Product.create(name: product[:title], url: product[:url], price: product[:price])
          end
          prod.images = imgs
          successful_results += 1
        end
        puts "Save to DB complete.\nStats:\n\t\tsaved: [#{successful_results}/#{successful_results+incomplete_results}]\n\t\tskipped: [#{incomplete_results}/#{successful_results+incomplete_results}]"
      end

      private

      def forbidden_params
        %w(
        pf_rd_
        )
      end

      def truncate_query(uri)
        query_components = URI.decode_www_form(uri.query)
        uri.query = URI.encode_www_form(query_components.reject {|param| forbidden_params.any? {|fp| param.first.match(fp)} })
      end

      def incomplete?(product)
        criteria = {
            empty_price: product[:price].to_s.empty?,
            nil_images: product[:images].nil?,
            empty_images: product[:images] && product[:images].empty?,
            inabsolute_url: [product[:url], product[:images]].flatten.any? {|url| !URI.parse(url).absolute? || url.size > 255}


        }
        criteria.values.any?
      end

      def extract(element, selector, extractor_fn)
        element.css(selector)
            .first
            .send(*extractor_fn)
            .to_s
            .strip
      rescue
        nil
      end
    end
    # Registry for all the crawlers added, so that we can manage all of them
    class Registry
      @@crawlers = []
      def self.register(crawler)
        @@crawlers << crawler
      end
      def self.crawlers
        @@crawlers
      end
    end
    module AgentFaker
      def self.headers(added_headers = {})
        {
            'User-Agent' => "Mozilla/#{rand(5)+1}.0 (#{['Macintosh','Linux', 'Windows'].sample}; Intel Mac OS X 10_#{(10..13).to_a.sample}_5) #{['AppleWebKit', 'Opera', 'Safari', 'Chrome'].sample}/535.36 (KHTML, like Gecko) Chrome/#{(55..66).to_a.sample}.0.3359.181 Safari/537.36",
            'accept-language' => 'en-US,en;q=0.9,ru;q=0.8',
            'accept' => 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8'
        }.merge(added_headers)
      end

      def self.nokogiri_page(url, added_headers = {})
        Nokogiri::HTML(open(url, headers(added_headers)))
      end
    end
  end
end