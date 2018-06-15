#!/usr/bin/env ruby

require 'base64'

load 'src/lib/bot/service/telegram.rb'
enc_tkn = "NTkyMjM4MDAyOkFBR1NraEE1U2FZbGNOX0R5c2xyZnprWkcyRjJrZDVwcjFZ\n"
bot = Bariga::Robot::Service::TelegramBot.new(name: 'Deals Dealer',
                                              username: 'deals_dealer_bot',
                                              token: Base64.decode64(enc_tkn))
bot.start
