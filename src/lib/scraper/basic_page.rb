module Bariga
  # module with basic functionality of a page (defined by a presence of unique hook selector)
  module BasicPage
    PAGE_HOOK = nil

    def current?
      page_hook = self.class.const_get(:PAGE_HOOK)
      LOGGER.debug("Checking URL [#{URI(@session.current_url).path}] content for presence of [#{page_hook}]")
      @session && !@session.find_all(page_hook).empty?
    end

    def open
      @session.visit @base_url
      self
    end
  end
end
