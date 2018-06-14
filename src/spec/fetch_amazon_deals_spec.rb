require 'rspec'
require_relative '../lib/scraper/amazon_deals_page.rb'
require_relative '../lib/scraper/amazon/today_deals_page.rb'

describe 'Amazon Scraping' do
  before(:all) do
    Capybara.configure do |config|
      config.run_server = false
      config.default_max_wait_time = 12
    end
    @session = Capybara::Session.new(:selenium_chrome_headless)
    @deals_page = Bariga::Amazon::TodayDealsPage.new(@session)
  end

  it 'should get good details' do
    @deals_page.open
    total_deals = @deals_page.total_deals
    puts "Found #{total_deals} deals on a page"
    expect(total_deals).to be > 10
  end

  it 'should fetch product data' do
    @active_deals = @deals_page.active_deals
    puts "Fetched [#{@active_deals.size}] product details"
    f = File.open('products.json', 'w+')
    f.write(JSON.generate(products: @active_deals.map(&:raw)))
    f.close
    expect(@active_deals.size).to be > 0
  end
end
