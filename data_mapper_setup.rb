require 'data_mapper'
require 'dm-postgres-adapter'
require_relative './models/user'
require_relative './models/linkedin'

if ENV['RACK_ENV'] == 'test'
  @database = "postgres://localhost/marketing_superstore_test"
else
  @database = "postgres://localhost/marketing_superstore_dev"
end

p "Running on #{@database}"
DataMapper.setup(:default, ENV['DATABASE_URL'] || @database)
DataMapper.finalize
DataMapper.auto_upgrade!
