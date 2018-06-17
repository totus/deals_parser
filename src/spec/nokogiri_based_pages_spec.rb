require 'rspec'
require 'json'
require_relative '../lib/crawler/6pm/new_arrivals_page.rb'
require_relative '../lib/crawler/vs/victorias_secret.rb'

describe 'Nokogiri-based Crawlers' do
  describe 'Crawl all of the following sites'
    Bariga::Crawler::Registry.crawlers.each do |crawler|
      it "Grabs data for #{crawler.class_info}" do
        current_one = crawler.send(:new)
        products = current_one.products
        current_one.save(products)
        expect(products.size).to be > 0
    end
  end
end
