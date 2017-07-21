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
ENV['LINKED_IN_ID'] ||= LinkedInAuth.get(1).client_id
ENV['LINKED_IN_SECRET'] ||= LinkedInAuth.get(1).client_secret
ENV['EMAIL_ADDRESS'] ||= LinkedInAuth.get(2).client_id
ENV['EMAIL_PASSWORD'] ||= LinkedInAuth.get(2).client_secret
ENV['GOOGLEMAPS_KEY'] ||= LinkedInAuth.get(3).client_id
ENV['S3_KEY'] ||= LinkedInAuth.get(4).client_id
ENV['S3_SECRET'] ||= LinkedInAuth.get(4).client_secret
ENV['WEBSITE_URL'] ||= 'http://localhost:9292'
ENV['SMTP_PORT'] ||= '25'

class MarketingSuperstore < Sinatra::Base
  enable :sessions
  set :session_secret, ENV['SESSION_SECRET'] || 'something'
  register Sinatra::Flash

  LinkedIn.configure do |config|
    config.redirect_uri  = ENV['WEBSITE_URL'] + '/login/callback'
  end

  get '/' do
    erb :index
  end

  get '/login' do
    if params[:invite]
      session[:invite_id] = params[:invite]
      session[:guest_id] = Invite.get(params[:invite]).invitee.id
      update_invite
    elsif params[:guest]
      session[:guest_id] = params[:guest]
      session[:invite_id] = nil
    else
      session[:invite_id] = nil
      session[:guest_id] = nil
    end
    oauth = get_oauth
    redirect oauth.auth_code_url
  end

  get '/login/callback' do
    token = get_token(params[:code])
    @api = LinkedIn::API.new(token)
    email_query = LinkedInAuth::EMAIL_QUERY + token.token + "&format=json"
    response = JSON.parse(open(email_query).read)
    update_invitee_record(@api, response["emailAddress"])
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
    @email = ENV['EMAIL_ADDRESS']
    erb :contact
  end

  get '/resolve' do
    @sent_to = params[:invite]
    @system = params[:system]
    erb :resolve
  end

  post '/resolve' do
    email = Invite.resolve_emails(params, session[:guest_id])
    guest = Invitee.get(session[:guest_id])
    guest.update(email: email)
    guest.save!
    redirect '/home'
  end

  get '/logout' do
    session.destroy
    redirect '/'
  end

  post '/question' do
    event = Event.get(params[:event]).title
    guest = Invitee.get(params[:guest])
    Email.question(event, guest, params[:message])
    redirect '/invite'
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
    @client_id = ENV['LINKED_IN_ID']
    @client_secret = ENV['LINKED_IN_SECRET']
    return LinkedIn::OAuth2.new(@client_id, @client_secret).get_access_token(code)
  end

  def update_invitee_record(linkedin_data, email)
    if session[:guest_id] == nil || Invitee.first(:linkedin_id => linkedin_data.profile.id)
      guest = Invitee.first_or_create(:linkedin_id => linkedin_data.profile.id)
      session[:guest_id] = guest.id
    else
      guest = Invitee.get(session[:guest_id])
    end
    Invitee.update_guest(guest, linkedin_data)
    check_email(email, guest.email)
  end

  def check_email(linkedin_email, guest_email)
    if guest_email != linkedin_email
      redirect "/resolve?invite=#{guest_email}&system=#{linkedin_email}"
    end
    if session[:invite_id] != nil
      invite_email = Invite.get(session[:invite_id]).invitee.email
      if invite_email != linkedin_email
        redirect "/resolve?invite=#{invite_email}&system=#{linkedin_email}"
      end
      if invite_email != guest_email
        redirect "/resolve?invite=#{invite_email}&system=#{guest_email}"
      end
    end
  end
end
