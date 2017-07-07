require 'net/smtp'

class Email
attr_reader :status
  def self.send(invite_address)
    msg = <<END_OF_MESSAGE
From: Peter Kerwood's Amazing Events <your@mail.address>
To: #{invite_address}
Subject: You have been invited to our next amazing event!

There will be a link to follow here...
END_OF_MESSAGE

    smtp = Net::SMTP.new 'smtp.gmail.com', 587
    smtp.enable_starttls
    smtp.start('www.gmail.com', 'snowdonialimited@gmail.com', 'b33chw00d', :login) do
      smtp.send_message(msg, 'snowdonialimited@gmail.com', invite_address)
    end
  end

end
