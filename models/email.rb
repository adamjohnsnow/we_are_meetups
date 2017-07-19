require 'net/smtp'
require_relative './linkedin'

class Email
attr_reader :status

  def self.send(invite_id)
    @invite = Invite.get(invite_id)
    @reply_url = LinkedInAuth::HOSTNAME

    msg = <<END_OF_MESSAGE
From: we are meetups <#{ENV['EMAIL_ADDRESS']}>
To: #{@invite.sent_to}
Subject: You have been invited to our next amazing event!
Content-Type: text/html;
<html>
Dear guest,<br><br>
You have been invited by #{@invite.invited_by} to attend our next exciting networking event.<br>
<h1>#{@invite.event.title}</h1>
<img src="#{@invite.event.image}" width="500px" height="100px"><br>
At:<strong> #{@invite.event.location}, #{@invite.event.postcode}</strong><br>
on #{@invite.event.date.strftime("%A %-d %B")} from #{@invite.event.time.strftime("%H:%M")} to #{@invite.event.end.strftime("%H:%M")}
<br><i>#{@invite.event.description}</i><br><br>
<strong>#{@invite.invited_by} said that they have invited you because:</strong><br>
<i>"#{@invite.reason}"</i><br>
<h3>Please respond by following <a href="#{@reply_url}/login?invite=#{@invite.id}">this link</a> or logging into <a href="#{@reply_url}">your account</a> via LinkedIn</h3>
<br>
Kindest regards,<br>
<h3>the we are meetups team</h3></html>
END_OF_MESSAGE

    smtp = Net::SMTP.new 'smtp.gmail.com', 587
    smtp.enable_starttls
    smtp.start('www.gmail.com', ENV['EMAIL_ADDRESS'], ENV['EMAIL_PASSWORD'], :login) do
      smtp.send_message(msg, ENV['EMAIL_ADDRESS'], @invite.sent_to)
    end
  end

  def self.send_update(event, subject, message)
    @reply_url = LinkedInAuth::HOSTNAME

    event.invites.each do |invite|
      if invite.response == 'Accepted'
        msg = <<END_OF_MESSAGE
From: we are meetups <#{ENV['EMAIL_ADDRESS']}>
To: #{invite.invitee.email}
Subject: #{subject} - #{event.title} update
Content-Type: text/html;
<html>
<h1>#{invite.event.title}</h1>
<img src="#{invite.event.image}" width="500px" height="100px"><br>
At:<strong> #{invite.event.location}, #{invite.event.postcode}</strong><br>
on #{invite.event.date.strftime("%A %-d %B")} from #{invite.event.time.strftime("%H:%M")} to #{invite.event.end.strftime("%H:%M")}
<br>
Dear #{invite.invitee.first_name},<br><br>
#{message}<br><br>
  <a href="#{@reply_url}">log in to your account to see your invites</a><br>
Kindest regards,<br>
<h3>the we are meetups team</h3></html>
END_OF_MESSAGE

        smtp = Net::SMTP.new 'smtp.gmail.com', 587
        smtp.enable_starttls
        smtp.start('www.gmail.com', ENV['EMAIL_ADDRESS'], ENV['EMAIL_PASSWORD'], :login) do
          smtp.send_message(msg, ENV['EMAIL_ADDRESS'], invite.invitee.email)
        end
      end
    end
  end

  def self.question(event, guest, message)

    msg = <<END_OF_MESSAGE
From: we are meetups <#{ENV['EMAIL_ADDRESS']}>
To: #{ENV['EMAIL_ADDRESS']}
Subject: #{guest.first_name} asked a question about #{event}
Content-Type: text/html;
<html>
reply to <a href="#{guest.email}">#{guest.email}</a><br>
#{message}
</html>
END_OF_MESSAGE

    smtp = Net::SMTP.new 'smtp.gmail.com', 587
    smtp.enable_starttls
    smtp.start('www.gmail.com', ENV['EMAIL_ADDRESS'], ENV['EMAIL_PASSWORD'], :login) do
      smtp.send_message(msg, ENV['EMAIL_ADDRESS'], ENV['EMAIL_ADDRESS'])
    end
  end
end
