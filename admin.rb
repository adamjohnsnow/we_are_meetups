require_relative './models/email'
require_relative './models/map'

class AdminRoutes < Sinatra::Base
  enable :sessions
  set :session_secret, ENV['SESSION_SECRET'] || 'something'
  register Sinatra::Flash

  get '/admin-login' do
    erb :login
  end

  post '/admin-login' do
    @user = User.login(params)
    bad_sign_in if @user.nil?
    session[:user] = @user.firstname
    session[:user_id] = @user.id
    redirect '/admin-home'
  end

  get '/admin-home' do
    redirect '/admin-login' if !session[:user]
    @events = Event.all(:date.gte => Date.today)
    @past_events = Event.all(:date.lt => Date.today)
    @user = session[:user]
    erb :admin
  end

  get '/new-event' do
    @user = session[:user_id]
    erb :new_event
  end

  post '/new-event' do
    unless params[:file] == nil
      event = Event.upload_image(params[:file])
      params[:image] = event
      params.tap{ |keys| keys.delete(:file) }
    end
    Event.create(params)
    redirect '/admin-home'
  end

  get '/admin-manage' do
    @users = Invitee.all
    @event = Event.get(params[:id])
    @attendees = Invite.all(:event_id => params[:id], :response => 'Attended')
    @accepteds = Invite.all(:event_id => params[:id], :response => 'Accepted')
    @pendings = Invite.all(:event_id => params[:id], :response.not => ['Accepted', 'Declined', 'Attended'])
    @declineds = Invite.all(:event_id => params[:id], :response => 'Declined')
    @map = Map.make_link(@event.location, @event.postcode)
    erb :event_admin
  end

  post '/save-event' do
    unless params[:file] == nil
      event = Event.upload_image(params[:file])
      params[:image] = event
      params.tap{ |keys| keys.delete(:file) }
    end
    @event = Event.get(params[:id])
    @event.update(params)
    @event.save!
    redirect '/admin-home'
  end

  post '/new-invite' do
    Invite.add_guest(params, session[:user_id])
    redirect "/admin-manage?id=#{params[:id]}"
  end

  post '/send-emails' do
    @event = Event.get(params[:id])
    @event.send_email
    redirect "/admin-manage?id=#{params[:id]}"
  end

  get '/new-user' do
    erb :new_user
  end

  post '/new-user' do
    mismatched_passwords if params[:password] != params[:verify_password]
    user = User.create(params[:firstname], params[:surname], params[:email], params[:password])
    bad_new_user unless user
    redirect '/admin-home'
  end

  get '/admin-users' do
    @users = Invitee.all(:last_name.like => '%' + params[:surname] + '%')
    erb :users
  end

  get '/attendees' do
    @invites = Invite.all(:event_id => params[:id])
    @invitee = Invitee.all
    erb :attendees
  end

  post '/send-message' do
    event = Event.get(params["event"])
    Email.send_update(event, params["subject"], params["message"])
    redirect '/attendees?id=' + event.id.to_s
  end

  post '/mark-attended' do
    invite = Invite.get(params[:id])
    invite.response = 'Attended'
    invite.save!
    Email.attended(invite.event, invite.invitee)
    redirect '/attendees?id=' + invite.event_id.to_s
  end
  private

  def mismatched_passwords
    flash.next[:notice] = 'Passwords did not match, try again'
    redirect '/new-user'
  end

  def bad_new_user
    flash.next[:notice] = 'User could not be registered, please try again'
    redirect '/new-user'
  end

  def bad_sign_in
    flash.next[:notice] = 'You could not be signed in, try again'
    redirect '/admin-login'
  end
end
