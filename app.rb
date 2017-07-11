require 'linkedin-oauth2'
require 'sinatra/base'
require 'sinatra/flash'
require 'pry'
require 'date'
require_relative './data_mapper_setup'
require_relative './models/linkedin'
require_relative './models/map'

ENV['RACK_ENV'] ||= 'development'

class MarketingSuperstore < Sinatra::Base
  enable :sessions
  set :session_secret, ENV['SESSION_SECRET'] || 'something'
  register Sinatra::Flash

  LinkedIn.configure do |config|
    config.redirect_uri  = LinkedInAuth::HOSTNAME + '/login/callback'
  end

  get '/reply' do
    session[:invite_id] = params[:invite]
    update_invite
    @oauth = get_oauth
    @linkedin_string = @oauth.auth_code_url
    redirect @linkedin_string
  end

  get '/login/callback' do
    token = get_token(params[:code])
    @api = LinkedIn::API.new(token)
    update_invitee(@api)
    redirect '/home'
  end

  get '/home' do
    @invite = Invite.get(session[:invite_id])
    @map = Map.make_link(@invite.event.location, @invite.event.postcode)
    @guest = @invite.invitee
    erb :home
  end

  post '/rsvp' do
    if Invite.get(session[:invite_id]).type == 'primary' && params[:guest_email] == ""
      flash.next[:notice] = 'As a primary guest, you must invite another attendee by providing their email<br>'
    else
      Invite.add_secondary(params, session[:invite_id])
    end
    redirect '/home'
  end

  private
  def update_invite
    @invite = Invite.get(session[:invite_id])
    @invite.update(response: 'clicked link')
    @invite.save!
  end

  def get_oauth
    client_id = LinkedInAuth.first.client_id
    client_secret = LinkedInAuth.first.client_secret
    return LinkedIn::OAuth2.new(client_id, client_secret)
  end

  def get_token(code)
    client_id = LinkedInAuth.first.client_id
    client_secret = LinkedInAuth.first.client_secret
    return LinkedIn::OAuth2.new(client_id, client_secret).get_access_token(code)
  end

  def update_invitee(linkedin_data)
    @invitee = Invite.get(session[:invite_id]).invitee
    @invitee.update(
    first_name: linkedin_data.profile.first_name,
    last_name: linkedin_data.profile.last_name,
    linkedin_id: linkedin_data.profile.id,
    linkedin_profile_pic: linkedin_data.picture_urls.all[0],
    linkedin_url: linkedin_data.profile.site_standard_profile_request.url,
    linkedin_headline: linkedin_data.profile.headline
    )
    @invitee.save!
  end
end
