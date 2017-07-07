require 'data_mapper'

class Invite
  include DataMapper::Resource

  property :id, Serial
  property :response, String
  property :invited_by, String
  property :reason, Text

  belongs_to :event
  belongs_to :invitee

  def self.add_guest(params)
    @guest = Invitee.first(:email => params[:email]) ||
             Invitee.create(email: params[:email])
    Invite.create(
      invitee_id: @guest.id,
      event_id: params[:id],
      reason: params[:reason],
      response: :pending,
      invited_by: 'admin'
      ) if @guest.invites(:event_id => params[:id]) == []
  end
end
