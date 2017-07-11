require 'net/smtp'
require_relative './linkedin'

class Email
attr_reader :status

  def self.send(invite_id)

    @email_account = LinkedInAuth.get(2)
    @invite = Invite.get(invite_id)
    ENV['RACK_ENV'] == 'development' ? @reply_url = LinkedInAuth::REDIRECT_LOGIN : @reply_url = LinkedInAuth::HEROKU

    msg = <<END_OF_MESSAGE
From: Peter Kerwood's Amazing Events <your@mail.address>
To: #{@invite.invitee.email}
Subject: You have been invited to our next amazing event!
Content-Type: text/html;
<html>
Dear guest,<br><br>
You have been invited by #{@invite.invited_by} to attend our next exciting networking event.<br>
<h2>#{@invite.event.title}</h2>
At:<strong> #{@invite.event.location}, #{@invite.event.postcode}</strong><br>
on #{@invite.event.date.strftime("%A %-d %B")} from #{@invite.event.time.strftime("%H:%M")}
<br><i>#{@invite.event.description}</i><br><br>
<strong>#{@invite.invited_by} said that they have invited you because:</strong><br>
<i>"#{@invite.reason}"</i><br>
<h3>Please respond by following <a href="#{@reply_url}/reply?invite=#{@invite.id}">this link</a> and logging in via LinkedIn</h3>
<br>
Kindest regards,<br>
<h3>The Marketing Superstore Team</h3></html>
END_OF_MESSAGE

    smtp = Net::SMTP.new 'smtp.gmail.com', 587
    smtp.enable_starttls
    smtp.start('www.gmail.com', @email_account.client_id, @email_account.client_secret, :login) do
      smtp.send_message(msg, @email_account.client_id, @invite.invitee.email)
    end
  end

end
