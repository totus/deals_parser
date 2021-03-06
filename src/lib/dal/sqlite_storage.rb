require 'sqlite3'

module Storage
  # Basic class to wrap interaction with SQLite DB
  class SQLite
    def initialize(db_file)
      @storage_file = db_file
      @db = SQLite3::Database.new @storage_file
    end

    def save
      nil?
    end
  end
end
