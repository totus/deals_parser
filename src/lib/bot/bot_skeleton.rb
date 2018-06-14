module Bariga
  module Robot
    class Skeleton
      def initialize props
        @name = props[:name] || props[:title]
        @username = props[:username]
        @api_token = props[:token]
      end
    end
  end
end