require_relative './deals_page.rb'

module Bariga
  module Amazon
    # TodayDealsPage - Today's deals on Amazon
    class WomenNewArrivals < DealsPage
      include BasicPage

      PAGE_HOOK = 'link[rel="canonical"][href*="node=17595940011"]'.freeze
      NEXT_PAGE_BUTTON_TRAIT = { css: 'a[title="Next Page"]', text: 'Next Page' }.freeze

      def initialize(session)
        super(session)
        @base_url = 'https://www.amazon.com/b?node=17595940011&lo=fashion&sort=date-desc-rank'
      end
    end
  end
end
