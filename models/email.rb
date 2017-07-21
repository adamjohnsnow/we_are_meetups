require 'net/smtp'
require 'mailit'
require 'mail'


class Email
attr_reader :status

  def self.send(invite_id)
    @invite = Invite.get(invite_id)
    @reply_url = ENV['WEBSITE_URL']
    subject = 'You have been invited to our next exciting event!'
    if @invite.invited_by.to_i > 0
      @invited_by = Invitee.get(@invite.invited_by.to_i).first_name + " " + Invitee.get(@invite.invited_by.to_i).last_name
    else
      @invited_by = @invite.invited_by
    end

    msg = "<html><body><div style='background-image: url(#{@invite.event.image}); padding-top: 100px;'></div> Dear guest,<br><br>You have been invited by #{@invited_by} to attend our next exciting networking event.<br>
          <h1>#{@invite.event.title}</h1>
          At:<strong> #{@invite.event.location}, #{@invite.event.postcode}</strong><br>
          on #{@invite.event.date.strftime('%A %-d %B')} from #{@invite.event.time.strftime('%H:%M')} to #{@invite.event.end.strftime('%H:%M')}
          <br><i>#{@invite.event.description}</i><br><br>
          <strong>#{@invited_by} said that they have invited you because:</strong><br>
          <i>'#{@invite.reason}'</i><br>
          <h3>Please respond by following <a href='#{ENV['WEBSITE_URL']}/login?invite=#{@invite.id}'>this link</a> or logging into <a href='#{ENV['WEBSITE_URL']}/login?guest=#{@invite.invitee.id}'>your account</a> via LinkedIn</h3>
          <br>
          Kindest regards,<br>
          <h3>the we are meetups team</h3></body></html>"

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
  def self.test_send(port)

      options = { :address              => 'smtp.123-reg.co.uk',
                  :port                 => port,
                  :domain               => '123-reg.co.uk',
                  :user_name            => ENV['EMAIL_ADDRESS'],
                  :password             => ENV['EMAIL_PASSWORD'],
                  :authentication       => 'login' }
       Mail.defaults do
        delivery_method :smtp, options
      end
      p options
       mail = Mail.new do
            from ENV['EMAIL_ADDRESS']
              to 'adamjohnsnow@icloud.com'
         subject 'This is a test email'
            body 'test'
       end
      mail.deliver!
  end
end
