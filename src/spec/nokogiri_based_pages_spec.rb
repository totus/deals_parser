require 'rspec'
require 'json'
require_relative '../lib/crawler/asos/asos_crawler.rb'
require_relative '../lib/crawler/6pm/new_arrivals_page.rb'
require_relative '../lib/crawler/vs/victorias_secret.rb'
require_relative '../lib/crawler/sd/sports_direct.rb'
require_relative '../lib/crawler/disney/disney.rb'
require_relative '../lib/crawler/amazon/new_arrivals_page.rb'
require_relative '../lib/crawler/amazon/amazon_crawler.rb'
require_relative '../lib/crawler/gymboree/gymboree.rb'
require_relative '../lib/crawler/yoox/yoox.rb'

describe 'Nokogiri-based Crawlers' do
  describe 'Crawl all of the following sites' do
    Bariga::Crawler::Registry.crawlers.each do |crawler|
      it "Grabs data for #{crawler.class_info[:name]}" do
        current_crawler = crawler.send(:new)
        products = current_crawler.products
        current_crawler.save(products)
        current_crawler.save_to_db(products)
        expect(products.size).to be > 0
      end
    end
  end
end
