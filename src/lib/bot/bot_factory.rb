require_relative '../dal/bot_config.rb'

module Bariga
  # Class that instantiates necessary bot based on the bot data provided
  class BotFactory
    Dir.new('./service').grep(/^\w+/).map { |service| require_relative "./service/#{service}" }

    def self.instantiate(bot_info)
      bot_info
    end
  end
end
