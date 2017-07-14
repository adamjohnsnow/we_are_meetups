require 'data_mapper'

class LinkedInAuth
  include DataMapper::Resource

  property :id, Serial
  property :client_id, String
  property :client_secret, String

  REDIRECT_LOGIN = 'http://localhost:9292'
  HEROKU = "https://wearemeetups.herokuapp.com"
  ENV['RACK_ENV'] == 'development' ? HOSTNAME = REDIRECT_LOGIN : HOSTNAME = HEROKU

end
