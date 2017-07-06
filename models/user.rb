require 'bcrypt'
require 'data_mapper'

class User
  include DataMapper::Resource
  include BCrypt

  property :id, Serial
  property :firstname, String
  property :surname, String
  property :email, String, :unique => true
  property :password_digest, Text

  def password=(pass)
    self.password_digest = BCrypt::Password.create(pass)
  end

  def self.create(firstname, surname, email, password)
    @email = email
    return if duplicate_email?
    new_user(firstname, surname, email, password)
    return @user
  end

  def self.new_user(firstname, surname, email, password)
    @user = User.new(
            firstname: firstname,
            surname: surname,
            email: email,
            )
    @user.password = password
    @user.save!
  end

  def self.login(params)
    @user = User.first(email: params[:email])
    @bcrypt = BCrypt::Password.new(@user.password_digest) if @user
    return nil unless @user && @bcrypt == params[:password]
    return @user
  end

  def self.duplicate_email?
    User.count(:conditions => ['email = ?', @email]).positive?
  end

end
