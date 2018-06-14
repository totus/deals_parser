require_relative '../model/good.rb'

module Bariga
  module Marketplace
    class Collection

      def self.get_last_products
        products = Bariga::Good.from_json File.open "../../../data/#{Dir.new('../../../data').entries.grep(/\.json/).sort.last}"
      end
    end
  end
end
