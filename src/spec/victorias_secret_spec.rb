require 'rspec'
require 'json'
require_relative '../lib/crawler/vs/victorias_secret.rb'

describe 'VS Crawler' do
  before(:all) { @crawler = Bariga::Crawler::VictoriasSecret::LingerieArrivals.new }
  it 'should grabs new lingerie arrivals' do
    products = @crawler.products
    @crawler.save(products)
    expect(products.size).to be > 0
  end
end