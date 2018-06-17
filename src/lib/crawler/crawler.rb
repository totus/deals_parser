require 'nokogiri'
require 'open-uri'
require 'json'

module Bariga
  module Crawler
    # mix-in with some crawler common functionality
    module BasicCrawler
      def absolutize_url(url)
        puts "Adding [#{@base_url}] to [#{url}]"
        URI.parse(url).scheme.eql?('https') ? url : URI.join(@base_url, url).to_s
      end

      def extract_data(element, selector, extractor_fn)
        element.css(selector)
               .first
               .send(*extractor_fn)
               .to_s
               .strip
      end

      def self.included(klass)
        Registry.register(klass)
      end

      def save(data)
        persist_data = { products: data, size: data.size }
        File.open(self.class.class_info[:file_pattern],'w+').write(JSON.generate(persist_data))
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
            'User-Agent' => "Mozilla/#{rand(5)+1}.0 (#{['Macintosh','Linux', 'Windows'].sample}; Intel Mac OS X 10_#{(10..13).to_a.sample}_5) #{['AppleWebKit', 'Opera', 'Safari', 'Chrome']}/535.36 (KHTML, like Gecko) Chrome/#{(55..66).to_a.sample}.0.3359.181 Safari/537.36",
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