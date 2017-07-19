require 'data_mapper'

class Invitee
  include DataMapper::Resource

  property :id, Serial
  property :email, String
  property :first_name, String
  property :last_name, String
  property :linkedin_id, String, :unique => true
  property :linkedin_url, String
  property :linkedin_profile_pic, String
  property :linkedin_headline, String
  property :last_logged_in, DateTime

  has n, :invites

  def self.update_guest(guest, linkedin_data)
    guest.update(
      linkedin_id: linkedin_data.profile.id,
      first_name: linkedin_data.profile.first_name,
      last_name: linkedin_data.profile.last_name,
      linkedin_profile_pic: linkedin_data.picture_urls.all[0],
      linkedin_url: linkedin_data.profile.site_standard_profile_request.url,
      linkedin_headline: linkedin_data.profile.headline,
      last_logged_in: Date.today
      )
    guest.save!
  end

  def self.remove(email, id)
    unused = Invitee.first(:email => email)
    if unused.id != id
      unused.destroy!
    end
  end
end
