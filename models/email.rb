require 'net/smtp'
require_relative './linkedin'

class Email
attr_reader :status

  def self.send(invite_address)
    @email_account = LinkedInAuth.get(2)
    
    msg = <<END_OF_MESSAGE
From: Peter Kerwood's Amazing Events <your@mail.address>
To: #{invite_address}
Subject: You have been invited to our next amazing event!

There will be a link to follow here...
END_OF_MESSAGE

    smtp = Net::SMTP.new 'smtp.gmail.com', 587
    smtp.enable_starttls
    smtp.start('www.gmail.com', @email_account.client_id, @email_account.client_secret, :login) do
      smtp.send_message(msg, @email_account.client_id, invite_address)
    end
  end

end
