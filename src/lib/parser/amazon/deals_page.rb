require_relative '../basic_page.rb'

module Bariga
  module Amazon
    # Common ancestor for all the Amazon's Deals pages of various types
    class DealsPage
      NEXT_PAGE_BUTTON_SELECTOR = 'a[href="#next"]'.freeze

      def initialize(session)
        @session = session
        @goods = []
      end

      protected

      def parse(use_selector = GoodCell::SELECTOR)
        LOGGER.debug("Started parsing #{@session.current_url}")
        goods = @session.find_all(use_selector)
        parsed = goods.map.with_object([]) do |good_element, res|
          res << GoodCell.new(good_element, @session)
          res.last.collect_data
        end.flatten
        LOGGER.debug("Parsed #{parsed.size} items")
        parsed
      end
    end
  end
end
