require 'logger'
require 'telegram/bot'
require_relative '../bot_skeleton.rb'
require_relative '../../marketplace/collection.rb'

LOGGER = Logger.new(STDOUT)

module Bariga
  module Robot
    module Service
      class ClientRegistry
        def self.clients
          User.all
        end

        def self.active_clients
          clients = User.all
          LOGGER.info("Overall #{clients.size} clients")
          clients.select do |client|
            specific_client_orders = Order.find_by(user_id: client.id)
            LOGGER.info("Checking client [#{client.id}] with orders [#{specific_client_orders}]")
            [specific_client_orders].flatten.any? { |order| order.end_date > Date.today }
          end
        end

        def self.add_client(user_object, description = '')
          User.create(userid: user_object.id,
                      is_bot: user_object.is_bot,
                      first_name: user_object.first_name,
                      last_name: user_object.last_name,
                      username: user_object.username,
                      description: description)
        end

        def self.add_order(user_id = 0, duration)
          current_day = Date.today
          Order.create(user_id: user_id, start_date: current_day, end_date: current_day.send("next_#{duration.last.gsub('s','')}".to_sym, duration.first.to_i))
        end
      end

      class BotConfig
        def self.is_admin?(user)
          LOGGER.info("Checking if user [#{user.username}] is admin")
          !(['IggyPob', 'totus_online'].grep(user.username).empty?)
        end
      end
      # Class that manages Telegram-api-based bot interaction
      class TelegramBot < Bariga::Robot::Skeleton
        def initialize(props)
          super(props)
        end

        def start
          @sent_to_channel = 0
          @client = Telegram::Bot::Client.run(@api_token) do |bot|
            deals = [] # Bariga::Marketplace::Collection.all_products
            pending_order = nil
            bot.listen do |message|
              LOGGER.info("Loaded #{deals.size} deals from DB")
              case message.forward_from
              when nil
              else
                if BotConfig.is_admin?(message.from)
                  client = ClientRegistry.add_client(message.forward_from)
                  pending_order.update(user_id: client.id)
                  bot.api.send_message(chat_id: message.chat.id, text: "Added new approval for #{client.username || client.first_name}")
                else
                  bot.api.send_message(chat_id: message.chat.id, text: 'Fuck off!')
                end
              end
              case message.text
              when %r{/approve\s*\d*\s*(?:days?|weeks?|months?)}
                LOGGER.info('Approval step')
                if BotConfig.is_admin?(message.from)
                  default_duration = ['1', 'month']
                  duration = message.text[/\d*\s*(?:days?|weeks?|months?)/].split
                  duration.unshift(default_duration.shift) while duration.size < 2
                  pending_order = ClientRegistry.add_order(0, duration)
                else
                  bot.api.send_message(chat_id: message.chat.id, text: 'Fuck off!')
                end
              when '/start'
                client_list = ClientRegistry.active_clients.map(&:userid)
                LOGGER.debug("Looking for a client #{message.from.id} in the #{client_list}")
                if client_list.include?(message.from.id)
                  bot.api.send_message(chat_id: message.chat.id, text: 'You are authorized bastard!')
                else
                  bot.api.send_message(chat_id: message.chat.id, text: 'You are NOT authorized bastard!')
                end
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
