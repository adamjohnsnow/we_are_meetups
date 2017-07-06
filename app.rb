require 'linkedin-oauth2'
require 'sinatra/base'
require 'sinatra/flash'
require 'pry'
require_relative './data_mapper_setup'
require_relative './models/linkedin'

ENV['RACK_ENV'] ||= 'development'

class MarketingSuperstore < Sinatra::Base
  enable :sessions
  set :session_secret, ENV['SESSION_SECRET'] || 'something'
  register Sinatra::Flash

  LinkedIn.configure do |config|

    # @hostname = request.host || "https://marketing-superstore-events.herokuapp.com"
    ENV['RACK_ENV'] == 'development' ? @hostname = 'http://localhost:9292' : @hostname = "https://marketing-superstore-events.herokuapp.com"
    config.redirect_uri  = @hostname + '/login/callback'
  end

  get '/' do
    p session
    oauth = LinkedIn::OAuth2.new(LinkedInAuth::CLIENT_ID, LinkedInAuth::CLIENT_SECRET)
    @linkedin_string = oauth.auth_code_url
    erb :index
  end

  get '/login/callback' do
    code = params[:code]
    session[:access_token] = LinkedIn::OAuth2.new(LinkedInAuth::CLIENT_ID, LinkedInAuth::CLIENT_SECRET).get_access_token(code)
    redirect '/home'

  end


  get '/home' do
    @api = LinkedIn::API.new(session[:access_token])

    erb :home
  end

  get '/logout' do
    session[:access_token] = nil
    redirect '/'
  end

end
