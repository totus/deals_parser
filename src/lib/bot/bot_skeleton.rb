module Bariga
  module Robot
    # bare bones for the bot
    class Skeleton
      def initialize(props)
        @name = props[:name] || props[:title]
        @username = props[:username]
        @api_token = props[:token]
      end
    end
  end
end
