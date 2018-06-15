require_relative '../model/good.rb'

module Bariga
  module Marketplace
    # Class representing a collection of goods fetched from marketplaces
    class Collection
      def self.last_fetched_products
        data_directory = File.join(File.expand_path(__dir__), '..', '..', 'data')
        last_file = Dir.new(data_directory).entries.grep(/\.json/).max
        Bariga::Good.from_json IO.read File.join(data_directory, last_file)
      end
    end
  end
end
