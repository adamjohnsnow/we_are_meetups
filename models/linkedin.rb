require 'data_mapper'

class LinkedInAuth
  include DataMapper::Resource

  property :id, Serial
  property :client_id, String
  property :client_secret, String

  REDIRECT_LOGIN = 'http://localhost:9292'
  HEROKU = "https://wearemeetups.herokuapp.com"
  ENV['RACK_ENV'] == 'development' ? HOSTNAME = REDIRECT_LOGIN : HOSTNAME = HEROKU
  EMAIL_QUERY = "https://api.linkedin.com/v1/people/~:(id,num-connections,email-address)?oauth2_access_token="
  LINKED_IN_ID = ENV['LINKED_IN_ID'] || LinkedInAuth.get(1).client_id
  LINKED_IN_SECRET = ENV['LINKED_IN_SECRET'] || LinkedInAuth.get(1).client_secret
  EMAIL_ADDRESS = ENV['EMAIL_ADDRESS'] || LinkedInAuth.get(2).client_id
  EMAIL_PASSWORD = ENV['EMAIL_ADDRESS'] || LinkedInAuth.get(2).client_secret
  GOOGLEMAPS_KEY = ENV['GOOGLEMAPS_KEY'] || LinkedInAuth.get(3).client_id
  S3_KEY = ENV['S3_KEY'] || LinkedInAuth.get(4).client_id
  S3_SECRET = ENV['S3_SECRET'] || LinkedInAuth.get(4).client_secret
end
