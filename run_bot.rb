#!/usr/bin/env ruby

load 'src/lib/bot/service/telegram.rb'
bot = Bariga::Robot::Service::TelegramBot.new(name: 'Deals Dealer', username: 'deals_dealer_bot', token: '592238002:AAGSkhA5SaYlcN_DyslrfzkZG2F2kd5pr1Y')
bot.start
