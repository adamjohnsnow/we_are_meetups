require 'data_mapper'

class Event
  include DataMapper::Resource

  property :id, Serial
  property :title, String
  property :description, Text
  property :location, String
  property :postcode, String
  property :date, Date
  property :time, Time

  belongs_to :user
  has n, :primary_invitees, through: Resource
  has n, :secondary_invitees, through: Resource

end
