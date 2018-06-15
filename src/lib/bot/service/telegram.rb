require 'logger'
require 'telegram/bot'
require_relative '../bot_skeleton.rb'
require_relative '../../marketplace/collection.rb'

LOGGER = Logger.new(STDOUT)

module Bariga
  module Robot
    module Service
      # Class that manages Telegram-api-based bot interaction
      class TelegramBot < Bariga::Robot::Skeleton
        def initialize(props)
          super(props)
        end

        def start
          @sent_to_channel = 0
          @client = Telegram::Bot::Client.run(@api_token) do |bot|
            bot.listen do |message|
              deals = Bariga::Marketplace::Collection.last_fetched_products
              case message.text
              when '/start'
                bot.api.send_message(chat_id: message.chat.id, text: 'Hello and fuck off, you bastard!')
              when %r{^/deals\s*\d*}
                count_of_deals = message.text[/^[^\d]+(\d+)/, 1].to_i || 10
                deals.first(count_of_deals).each do |product|
                  LOGGER.debug("Sending product #{product}")
                  bot.api.send_message(chat_id: message.chat.id, text: product.as_message, parse_mode: 'Markdown')
                end
              when %r{^/publish\s*(?:next|prev)?\s*\d*}
                count_of_deals = message.text[/\d+/].to_i || 10
                @sent_to_channel = 0 if @sent_to_channel > deals.size
                LOGGER.info("Requested to publish #{count_of_deals} goods")
                deals[@sent_to_channel, count_of_deals].each do |product|
                  next unless product.images.first.start_with?('http')
                  bot.api.send_photo(chat_id: '-1001257936261',
                                     photo: product.images.first,
                                     parse_mode: 'Markdown',
                                     caption: product.as_message)
                  # bot.api.send_message(chat_id: '-1001257936261', text: product.as_message, disable_web_page_preview: true)
                end
                @sent_to_channel += count_of_deals
                LOGGER.info("Processed #{count_of_deals}")
              end
            end
          end
        end

        def send_message_to(destination, message, _options = {})
          @client.api.send_message(chat_id: destination, text: message)
        end
      end
    end
  end
end
