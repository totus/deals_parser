require_relative '../basic_page.rb'

module Bariga
  module Amazon
    # Common ancestor for all the Amazon's Deals pages of various types
    class DealsPage
      NEXT_PAGE_BUTTON_TRAIT = { css: 'a[href="#next"]', text: 'Next' }.freeze

      def initialize(session)
        @session = session
        @goods = []
      end

      protected

      def parse(use_selector = GoodCell::SELECTOR)
        LOGGER.debug("Started parsing #{@session.current_url}")
        goods = @session.find_all(use_selector)
        LOGGER.debug("Found #{goods.size} potentially interesting objects")
        parsed = goods.map.with_object([]) do |good_element, res|
          cell = GoodCell.new(good_element, @session)
          LOGGER.debug("Got #{cell.collect_data}")
          res << cell unless cell.collect_data.empty?
        end.flatten
        LOGGER.debug("Finished parsing #{goods.size} items, collected #{parsed.size} items")
        parsed
      end
    end
  end
end
