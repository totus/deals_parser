require 'rspec'
require_relative '../lib/crawler/amazon/new_arrivals_page.rb'

describe 'Arrival Grabber' do
  describe 'Grabs new arrivals' do
    context 'for Men' do
      before(:all) do
        @men_arrival_page = Bariga::Amazon::MenNewArrivals.new
      end
      it 'Fetches deals from the marketplace' do
        expect(@men_arrival_page.deals.size).to be > 0
      end
      it 'Persists deals to file system' do
        file_name = "#{Date.today.strftime('%Y_%m_%d')}_men_products.json"
        @men_arrival_page.save_deals file_name
        expect(File.open(file_name, 'r').size).to be > 0
      end
    end
    context 'for Women' do
      before(:all) do
        @women_arrival_page = Bariga::Amazon::WomenNewArrivals.new
      end
      it 'Fetches deals from the marketplace' do
        expect(@women_arrival_page.deals.size).to be > 0
      end
      it 'Persists deals to file system' do
        file_name = "#{Date.today.strftime('%Y_%m_%d')}_women_products.json"
        @women_arrival_page.save_deals file_name
        expect(File.open(file_name, 'r').size).to be > 0
      end
    end
  end
end