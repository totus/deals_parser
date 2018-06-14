require_relative '../dal/bot_config.rb'

module Bariga
  class BotFactory

    Dir.new('./service').grep(/^\w+/).map { |service| require_relative "./service/#{service}" }

    def self.instantiate(bot_info)
      bot_info
    end
  end
end