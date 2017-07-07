require 'data_mapper'
require_relative './email'

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

  def send_email
    @send_to = Invite.all(:event_id => self.id, :response => 'pending')
    @send_to.each do |invite|
      email = Email.send(invite.id)
      email.status == "250" ? invite.response = 'sent' : invite.response = 'failed to send'
      invite.save!
    end
  end

end
