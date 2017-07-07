require 'data_mapper'

class Event
  include DataMapper::Resource

  property :id, Serial
  property :title, String
  property :description, Text
  property :location, String
  property :postcode, String
  property :date, Date
  property :time, DateTime

  belongs_to :user
  has n, :invites

end
