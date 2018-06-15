require_relative '../model/good.rb'

module Bariga
  module Marketplace
    # Class representing a collection of goods fetched from marketplaces
    class Collection
      def self.last_fetched_products
        Bariga::Good.from_json File.open "../../../data/#{Dir.new('../../../data').entries.grep(/\.json/).max}"
      end
    end
  end
end
