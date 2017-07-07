require_relative '../models/email'

class AdminRoutes < Sinatra::Base
  enable :sessions
  set :session_secret, ENV['SESSION_SECRET'] || 'something'
  register Sinatra::Flash

  get '/admin/login' do
    erb :login
  end

  post '/admin/login' do
    @user = User.login(params)
    bad_sign_in if @user.nil?
    session[:user] = @user.firstname
    session[:user_id] = @user.id
    redirect '/admin/home'
  end

  get '/admin/home' do
    @events = Event.all(:date.gte => Date.today)
    @user = session[:user]
    erb :admin
  end

  get '/new-event' do
    @user = session[:user_id]
    erb :new_event
  end

  post '/new-event' do
    @event = Event.create(params)
    redirect '/admin/home'
  end

  get '/admin/manage' do
    @event = Event.get(params[:id])
    erb :event_admin
  end

  post '/save-event' do
    @event = Event.get(params[:id])
    @event.update(params)
    @event.save!
    redirect '/admin/home'
  end

  get '/admin/invites' do
    @event = Event.get(params[:id])
    @invites = Invite.all(:event_id => params[:id], :order => [:response.asc])
    erb :invites
  end

  post '/new-invite' do
    Invite.add_guest(params)
    redirect "/admin/invites?id=#{params[:id]}"
  end

  post '/send-emails' do
    @event = Event.get(params[:id])
    @event.send_email
    redirect "/admin/invites?id=#{params[:id]}"
  end
  private

  def bad_sign_in
    flash.next[:notice] = 'you could not be signed in, try again'
    redirect '/admin/login'
  end
end
