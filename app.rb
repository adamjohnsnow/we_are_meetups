require 'linkedin-oauth2'
require 'sinatra/base'
require 'sinatra/flash'
require 'pry'
require 'date'
require 'open-uri'
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

  get '/' do
    @token = '6033867.a321c67.b6a7c62475d7433faf9d4d5a0cfd8b6f'
    erb :index
  end

  get '/reply' do
    session[:invite_id] = params[:invite]
    update_invite if params[:invite]
    @oauth = get_oauth
    @linkedin_string = @oauth.auth_code_url
    redirect @linkedin_string
  end

  get '/login/callback' do
    token = get_token(params[:code])
    @api = LinkedIn::API.new(token)
    email_query = LinkedInAuth::EMAIL_QUERY + token.token + "&format=json"
    update_invitee(@api, email_query)
    if session[:invite_id] == nil
      redirect '/home'
    else
      redirect '/invite'
    end
  end

  get '/invites' do
    session[:invite_id] = params[:id]
    update_invite
    redirect '/invite'
  end

  get '/invite' do
    @invite = Invite.get(session[:invite_id])
    @map = Map.make_link(@invite.event.location, @invite.event.postcode)
    @guest = @invite.invitee
    erb :invite
  end

  get '/home' do
    if session[:guest_id] == nil
      redirect '/reply'
    end
    @user = Invitee.get(session[:guest_id])
    @invites = Event.all(:date.gte => Date.today).invites.all(:invitee_id => session[:guest_id])
    @past_invites = @user.invites.all(:response => 'Attended')
    erb :home
  end

  post '/rsvp' do
    if params[:rsvp] == 'Declined'
      invite = Invite.get(session[:invite_id])
      invite.update(response: 'Declined')
      invite.save!
      else
      if Invite.get(session[:invite_id]).type == 'primary' && params[:guest_email] == ""
        flash.next[:notice] = 'As a primary guest, you must invite another attendee by providing their email<br>'
      else
        Invite.add_secondary(params, session[:invite_id])
      end
    end
    redirect '/invite'
  end

  get '/guest-list' do
    @event = Event.get(params[:id])
    @invites = @event.invites.all(:response => ["Accepted", "Attended"])
    erb :guest_list
  end

  get '/about' do
    erb :about
  end

  get '/contact' do
    erb :contact
  end

  private
  def update_invite
      @invite = Invite.get(session[:invite_id])
      @invite.update(response: 'Invite Received') if @invite.response == 'Invite Sent'
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

  def update_invitee(linkedin_data, email_query)
    response = JSON.parse(open(email_query).read)
    @invitee = Invitee.first_or_create(:email => response["emailAddress"])
    @invitee.update(
    first_name: linkedin_data.profile.first_name,
    last_name: linkedin_data.profile.last_name,
    linkedin_id: linkedin_data.profile.id,
    linkedin_profile_pic: linkedin_data.picture_urls.all[0],
    linkedin_url: linkedin_data.profile.site_standard_profile_request.url,
    linkedin_headline: linkedin_data.profile.headline
    )
    @invitee.save!
    session[:guest_id] = @invitee.id
  end
end
