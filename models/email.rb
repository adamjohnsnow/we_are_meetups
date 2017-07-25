require 'net/smtp'
require 'mailit'
require 'mail'


class Email
attr_reader :status


  def self.send_email(email, subject, message)

    mail = Mailit::Mail.new
    mail.to = email
    mail.from = "#{ENV['EMAIL_ADDRESS']}"
    mail.subject = subject
    mail.html = message

    mailer = Mailit::Mailer.new

    mailer.send(mail, :server => 'smtp.123-reg.co.uk', :port => ENV['SMTP_PORT'],
      :domain => '123-reg.co.uk', :password => ENV['EMAIL_PASSWORD'])
    end

  def self.invitation(invite_id)
    @invite = Invite.get(invite_id)
    subject = 'You have been invited to our next exciting event!'
    if @invite.invited_by.to_i > 0
      @invited_by = Invitee.get(@invite.invited_by.to_i).first_name + " " + Invitee.get(@invite.invited_by.to_i).last_name
    else
      @invited_by = @invite.invited_by
    end

    msg = "<html><body><div style='background-image: url(#{@invite.event.image}); padding-top: 30px; padding-bottom: 30px; text-align: center;'><h1 style='color: white;'>we are meetups</h1></div>
          <br>Dear guest,<br><br>You have been invited by #{@invited_by} to attend our next exciting networking event.<br>
          <h2 style='text-transform: uppercase;'>#{@invite.event.title}</h2>
          <strong>Venue:</strong> #{@invite.event.location}, #{@invite.event.postcode}<br>
          <strong>Date & Time:</strong> #{@invite.event.date.strftime('%A %-d %B')} from #{@invite.event.time.strftime('%H:%M')} to #{@invite.event.end.strftime('%H:%M')}
          <br><br><i>#{@invite.event.description}</i><br><br>
          <strong>#{@invited_by} said that they have invited you because:</strong><br>
          <i>'#{@invite.reason}'</i><br>
          <strong>Please respond by following <a href='#{ENV['WEBSITE_URL']}/login?invite=#{@invite.id}'>this link</a> or logging into <a href='#{ENV['WEBSITE_URL']}/login?guest=#{@invite.invitee.id}'>your account</a> via LinkedIn</strong>
          <br><br>
          Kindest regards,<br><br>
          <strong>the we are meetups team</strong></body></html>"

    send_email(@invite.invitee.email, subject, msg)
  end

  def self.send_update(event, subject, message)

    event.invites.each do |invite|
      if invite.response == 'Accepted'
        msg = "<html><div style='background-image: url(#{invite.event.image}); padding-top: 100px;'></div>
        <h1>#{invite.event.title}</h1>
        At:<strong> #{invite.event.location}, #{invite.event.postcode}</strong><br>
        on #{invite.event.date.strftime("%A %-d %B")} from #{invite.event.time.strftime("%H:%M")} to #{invite.event.end.strftime("%H:%M")}
        <br>
        Dear #{invite.invitee.first_name},<br><br>
        #{message}<br><br>
          <a href='#{ENV['WEBSITE_URL']}'>log in to your account to see your invites</a><br>
        Kindest regards,<br>
        <h3>the we are meetups team</h3></html>"

        subject = "#{subject} - #{event.title} update"

        send_email(invite.invitee.email, subject, msg)
      end
    end
  end

  def self.question(event, guest, message)
    msg = "reply to <a href='#{guest.email}'>#{guest.email}</a><br>#{message}"
    subject = "#{guest.first_name} asked a question about #{event}"
    send_email(ENV['EMAIL_ADDRESS'], subject, msg)
  end

  def self.attended(event, guest)
    subject = "Thank you for attending #{event.title}"
    msg = "<html><div style='background-image: url(#{event.image}); padding-top: 30px; padding-bottom: 30px; text-align: center;'><h1 style='color: white;'>we are meetups</h1></div>
    <h1>#{event.title}</h1>
    Dear #{guest.first_name},<br><br>
    Thank you for attending our recent event, #{event.title}.<br><br>
    If you wish to connect with any of the other attendees you met there,
      <a href='#{ENV['WEBSITE_URL']}'>log in to your account</a> to see guest lists events you have attended.<br>
      We look forward to seeing you at another of our events soon!<br><br>
    Kindest regards,<br>
    <h3>the we are meetups team</h3></html>"
    send_email(guest.email, subject, msg)
  end

end
