require 'data_mapper'

class Invite
  include DataMapper::Resource

  property :id, Serial
  property :response, String
  property :primary, Boolean
  property :reason, Text

  belongs_to :event
  belongs_to :invitee
end
