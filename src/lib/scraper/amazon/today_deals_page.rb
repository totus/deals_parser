require_relative './deals_page.rb'

module Bariga
  module Amazon
    # TodayDealsPage - Today's deals on Amazon
    class TodayDealsPage < DealsPage
      include BasicPage

      PAGE_HOOK = 'link[rel="canonical"][href="https://www.amazon.com/gp/goldbox/"]'.freeze
      SUMMARY_BAR_CSS = 'div[class*="filterSummaryBar"]'.freeze
      COUNT_REGEX = /^[^\d]+\d+(?:-\d+)?(?:\s+\b[^\d]+\b\s+)*(\d+)/

      def initialize(session)
        super(session)
        @base_url = 'https://www.amazon.com/gp/goldbox/'
      end

      def total_deals
        @total_deals ||= @session.find(SUMMARY_BAR_CSS).text[COUNT_REGEX, 1].to_i
      end

      def active_deals
        process_raw(raw_deals.flatten)
      end

      def raw_deals
        @raw_deals ||= fetch_all
      end

      def open
        @session.visit @base_url
        self
      end

      private

      def process_raw(deals)
        counter = 0
        deals.map do |product|
          LOGGER.debug "Opening url #{product}"
          @session.visit product.url
          page = GoodPage.new(@session)
          LOGGER.debug "processing element ##{counter += 1}"
          # select_first_interim unless page.current?
          next unless page.current? # TODO: properly process non-single items instead of skipping them
          attributes = page.fetch
          good = product.to_obj(attributes)
          good.save
          good
        end.compact
      end

      def fetch_all
        @goods << parse
        @goods << fetch_next while next_page?
        LOGGER.info "Parsed and fetched #{@goods.flatten.compact.size} items"
        @goods.flatten.compact
      end

      def select_first_interim
        interim_link = (@session.find_all('a[class*="access-detail-page"]').first ||
            @session.find_all('a[class*="asin-link"]').first ||
            @session.find_all('div[class*="card-details"]').first.find_all('a').first)
        @session.visit interim_link[:href]
      end

      def fetch_next
        LOGGER.info 'Fetching next page'
        @session.find(NEXT_PAGE_BUTTON_TRAIT[:css], text: NEXT_PAGE_BUTTON_TRAIT[:text]).click
        parse
      end

      def next_page?
        !@session.find_all(NEXT_PAGE_BUTTON_TRAIT[:css], text: NEXT_PAGE_BUTTON_TRAIT[:text]).empty?
      end
    end
  end
end
