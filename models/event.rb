require 'data_mapper'
require 'aws-sdk'
require_relative './email'

class Event
  include DataMapper::Resource

  property :id, Serial
  property :title, String
  property :description, Text
  property :location, String
  property :postcode, String
  property :date, Date
  property :time, DateTime
  property :end, DateTime
  property :image, URI

  belongs_to :user
  has n, :invites

  def send_email
    @send_to = Invite.all(:event_id => self.id, :response => 'Invite not sent')
    @send_to.each do |invite|
      email = Email.invitation(invite.id)
      email.status == "250" ? invite.response = 'Invite Sent' : invite.response = 'Invite failed to send'
      invite.save!
    end
  end

  def self.upload_image(upload)
    aws_creds
    @bucket = 'wearemeetups'
    @file = upload[:tempfile]
    @filename = upload[:filename]
    aws_upload
    return @url
  end

  def self.aws_creds
    aws_key = ENV['S3_KEY']
    aws_secret = ENV['S3_SECRET']
    Aws.config.update({
      region: 'eu-west-2',
      credentials: Aws::Credentials.new(aws_key, aws_secret)
    })
  end

  def self.aws_upload
    s3 = Aws::S3::Resource.new()
    obj = s3.bucket(@bucket).object("uploads/#{@filename}")
    obj.upload_file(@file)
    @url = obj.public_url
  end
end
