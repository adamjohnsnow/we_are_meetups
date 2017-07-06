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
    erb :new_event
  end

  post '/new-event' do
    Event.create(
      title: params[:title],
      description: params[:description],
      location: params[:location],
      postcode: params[:postcode],
      date: params[:date],
      time: params[:time],
      user_id: session[:user_id]
      )
    redirect '/admin/home'
  end

  private

  def bad_sign_in
    flash.next[:notice] = 'you could not be signed in, try again'
    redirect '/admin/login'
  end
end
