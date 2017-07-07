require 'net/smtp'

class Email
attr_reader :status
  def self.send(invite_address)
    msg = "Subject: An invite from Marketing Superstore\n\nIf you can read this, it works!!"
    smtp = Net::SMTP.new 'smtp.gmail.com', 587
    smtp.enable_starttls
    smtp.start('www.gmail.com', 'snowdonialimited@gmail.com', 'b33chw00d', :login) do
      smtp.send_message(msg, 'snowdonialimited@gmail.com', invite_address)
    end
  end

end
