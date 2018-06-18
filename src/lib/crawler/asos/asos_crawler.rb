module Bariga
  module Crawler
    module Asos
      module Loadable
        def load_all
          @page = AgentFaker.nokogiri_page(URI.join(@page_url, 'page=28').to_s)
        end
      end
      class DesignerSales

      end
    end
  end
end