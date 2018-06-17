require 'rspec'
require 'json'
require_relative '../lib/crawler/vs/victorias_secret.rb'

describe 'VS Crawler' do
  it 'should allow to grab using all crawlers' do
    Bariga::Crawler::Registry.crawlers.each do |crawler|
      current_one = crawler.send(:new)
      products = current_one.products
      current_one.save(products)
      expect(products.size).to be > 0
    end
  end
end