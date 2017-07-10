require 'data_mapper'

class Invite
  include DataMapper::Resource

  property :id, Serial
  property :response, String
  property :invited_by, String
  property :reason, Text
  property :type, String

  belongs_to :event
  belongs_to :invitee

  def self.add_guest(params, user_id)
    @guest = Invitee.first(:email => params[:email]) ||
             Invitee.create(email: params[:email])
    Invite.create(
      invitee_id: @guest.id,
      event_id: params[:id],
      reason: params[:reason],
      response: :pending,
      invited_by: "#{User.get(user_id).firstname} #{User.get(user_id).surname}",
      type: :primary
      ) if @guest.invites(:event_id => params[:id]) == []
  end

  def self.add_secondary(params, invite_id)
    response = Invite.get(invite_id)
    response.update(response: params[:rsvp])
    response.save!

    if response.type == 'primary'
      @guest = Invitee.first(:email => params[:guest_email]) ||
               Invitee.create(email: params[:guest_email])

      if @guest.invites(:event_id => params[:event_id]) == []
      @invite = Invite.create(
        invitee_id: @guest.id,
        event_id: params[:event_id],
        reason: params[:reason],
        response: :pending,
        invited_by: "#{Invitee.get(params[:invitee_id]).first_name} #{Invitee.get(params[:invitee_id]).last_name}",
        type: :secondary
        )
        Email.send(@invite.id)
      else
        p 'already invited'
      end
    end
  end
end
