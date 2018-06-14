require_relative '../model/good.rb'

module Bariga
  module Marketplace
    class Collection

      def self.get_last_products
        products = Bariga::Good.from_json File.open '../../../data/products.json'
      end
    end
  end
end
