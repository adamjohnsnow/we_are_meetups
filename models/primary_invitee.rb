require 'data_mapper'

class Invitee
  include DataMapper::Resource

  property :id, Serial
  property :email, String, :unique => true
  property :first_name, String
  property :last_name, String
  property :linkedin_id, String
  property :linkedin_url, String
  property :linkedin_profile_pic, String
  property :linkedin_headline, String

  has n, :invites
end