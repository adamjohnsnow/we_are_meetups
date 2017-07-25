require 'data_mapper'

class Invite
  include DataMapper::Resource

  property :id, Serial
  property :response, String
  property :invited_by, String
  property :reason, Text
  property :type, String
  property :sent_to, String

  belongs_to :event
  belongs_to :invitee

  def self.add_guest(params, user_id)
    @guest = Invitee.first_or_create(:email => params[:email])
    Invite.create(
      invitee_id: @guest.id,
      event_id: params[:id],
      reason: params[:reason],
      response: 'Invite not sent',
      invited_by: "#{User.get(user_id).firstname} #{User.get(user_id).surname}",
      type: "primary",
      sent_to: params[:email]
      ) if @guest.invites(:event_id => params[:id]) == []
  end

  def self.add_secondary(params, invite_id)
    response = Invite.get(invite_id)
    @guest = Invitee.first_or_create(:email => params[:email])
    if @guest.invites(:event_id => params[:event_id]) == []
      @invite = Invite.create(
        invitee_id: @guest.id,
        event_id: params[:event_id],
        reason: params[:reason],
        response: 'Invite Sent',
        invited_by: params[:invitee_id],
        type: "secondary",
        sent_to: params[:email]
        )
      Email.invitation(@invite.id)
      response.update(response: params[:rsvp])
      response.save!
      return :ok
    else
      return :fail
    end
  end


  def self.resolve_emails(params ,user_id)
    if params["email"] == params.keys[0]
      invites = Invite.all(:sent_to => params["linkedin"])
      remove = params["linkedin"]
      email = params["sent_to"]
    else
      invites = Invite.all(:sent_to => params["sent_to"])
      remove = params["sent_to"]
      email = params["linkedin"]
    end
    invites.each do |invite|
      invite.update(invitee_id: user_id.to_i)
      invite.save!
    end
    Invitee.remove(remove, email, user_id.to_i) if remove == params["sent_to"]
    return email
  end
end
