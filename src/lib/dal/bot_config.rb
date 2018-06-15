require 'sqlite3'

module Bariga
  # Class that will fetch bot configuration from the database and serve as a single point of bot management
  class BotConfig
    LOCAL_DB = SQLite3::Database.open '../../config/config_db'

    def self.list_bots
      LOCAL_DB.execute 'select b.title, b.username, b.description, bs.name from bots b, bot_services bs'
    end
  end
end
