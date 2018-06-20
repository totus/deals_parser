require 'active_record'

ActiveRecord::Base.establish_connection(
  adapter: 'mysql2',
  host: 'maria-synology',
  port: '3307',
  username: 'root',
  password: ENV['mariadbpwd'],
  database: 'dwh'
)

class Image < ActiveRecord::Base
  self.table_name = 'images'
  has_and_belongs_to_many :products, through: :images_products
end

class Product < ActiveRecord::Base
  self.table_name = 'products'

  validates_presence_of :name
  validates_presence_of :url
  validates_presence_of :price
  has_and_belongs_to_many :images, through: :images_products
end
