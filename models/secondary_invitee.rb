require 'data_mapper'

class SecondaryInvitee
  include DataMapper::Resource

  property :id, Serial
  property :first_name, String
  property :last_name, String
  property :linkedin_id, String
  property :linkedin_url, String
  property :linkedin_profile_pic, String
  property :linkedin_headline, String
  property :email, String

  belongs_to :primary_invitee
  has n, :events, through: Resource

end
