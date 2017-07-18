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
ENV['LINKED_IN_ID'] =|| LinkedInAuth.get(1).client_id
ENV['LINKED_IN_SECRET'] =|| LinkedInAuth.get(1).client_secret
ENV['EMAIL_ADDRESS'] =|| LinkedInAuth.get(2).client_id
ENV['EMAIL_ADDRESS'] =|| LinkedInAuth.get(2).client_secret
ENV['GOOGLEMAPS_KEY'] =|| LinkedInAuth.get(3).client_id
ENV['S3_KEY'] =|| LinkedInAuth.get(4).client_id
ENV['S3_SECRET'] =|| LinkedInAuth.get(4).client_secret

class MarketingSuperstore < Sinatra::Base
  enable :sessions
  set :session_secret, ENV['SESSION_SECRET'] || 'something'
  register Sinatra::Flash

  LinkedIn.configure do |config|
    config.redirect_uri  = LinkedInAuth::HOSTNAME + '/login/callback'
  end

  get '/' do
    erb :index
  end

  get '/login' do
    if params[:invite]
      session[:invite_id] = params[:invite]
      session[:guest_id] = Invite.get(params[:invite]).invitee_id
      update_invite
    end
    oauth = get_oauth
    redirect oauth.auth_code_url
  end

  get '/login/callback' do
    token = get_token(params[:code])
    @api = LinkedIn::API.new(token)
    email_query = LinkedInAuth::EMAIL_QUERY + token.token + "&format=json"
    response = JSON.parse(open(email_query).read)
    update_invitee(@api, response)
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
    if Invitee.get(session[:guest_id]).email == Invite.get(session[:invite_id]).sent_to
      @invite = Invite.get(session[:invite_id])
      @map = Map.make_link(@invite.event.location, @invite.event.postcode)
      @guest = @invite.invitee
      erb :invite
    else
      redirect "/resolve?invite=#{Invitee.get(session[:guest_id]).email}&system=#{Invite.get(session[:invite_id]).sent_to}"
    end
  end

  get '/home' do
    if session[:guest_id] == nil
      redirect '/login'
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

  get '/resolve' do
    @sent_to = params[:invite]
    @system = params[:system]
    erb :resolve
  end

  private
  def update_invite
      @invite = Invite.get(session[:invite_id])
      @invite.update(response: 'Invite Received') if @invite.response == 'Invite Sent'
      @invite.save!
  end

  def get_oauth
    @client_id = ENV['LINKED_IN_ID']
    @client_secret = ENV['LINKED_IN_SECRET']
    return LinkedIn::OAuth2.new(@client_id, @client_secret)
  end

  def get_token(code)
    return LinkedIn::OAuth2.new(@client_id, @client_secret).get_access_token(code)
  end

  def update_invitee(linkedin_data, response)
    if session[:guest_id] != nil
      if Invitee.get(session[:guest_id]).email != response["emailAddress"]
        session[:linkedin_data] = linkedin_data
        redirect "/resolve?invite=#{Invitee.get(session[:guest_id]).email}&system=#{response["emailAddress"]}"
      end
    end
    update_invitee_record(linkedin_data, response["emailAddress"])
  end

  def update_invitee_record(linkedin_data, email)
    guest = Invitee.first_or_create(:email => email)
    guest.update(
    first_name: linkedin_data.profile.first_name,
    last_name: linkedin_data.profile.last_name,
    linkedin_id: linkedin_data.profile.id,
    linkedin_profile_pic: linkedin_data.picture_urls.all[0],
    linkedin_url: linkedin_data.profile.site_standard_profile_request.url,
    linkedin_headline: linkedin_data.profile.headline,
    last_logged_in: Date.today
    )
    guest.save!
    session[:guest_id] = guest.id
  end
end
