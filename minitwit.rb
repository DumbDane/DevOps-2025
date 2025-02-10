require 'sinatra/base'
require 'rack-flash'
require 'sqlite3'
require 'bcrypt'
require 'erb'
require 'rack/session/cookie'
require 'securerandom'

class MiniTwit < Sinatra::Base
  SECRET_KEY = SecureRandom.hex(32)
  PER_PAGE = 30
  DATABASE = './db/minitwit.db'
  
  # Configure session management inside a configure block
  configure do
    enable :sessions
    use Rack::Session::Cookie, key: 'rack.session', secret: SECRET_KEY
    use Rack::Flash
  end

  # Database connection helper
  def connect_db
    SQLite3::Database.new(DATABASE, results_as_hash: true)
  end

  # Query helper
  def query_db(query, args = [], one = false)
    db = connect_db
    result = db.execute(query, args)
    db.close
    one ? result.first : result
  end

  # Get user ID by username
  def get_user_id(username)
    user = query_db('SELECT user_id FROM user WHERE username = ?', [username], true)
    user ? user['user_id'] : nil
  end

  # Format datetime
  def format_datetime(timestamp)
    Time.at(timestamp).utc.strftime('%Y-%m-%d @ %H:%M')
  end

  # Gravatar URL
  def gravatar_url(email, size = 80)
    hash = Digest::MD5.hexdigest(email.strip.downcase)
    "http://www.gravatar.com/avatar/#{hash}?d=identicon&s=#{size}"
  end

  # Before request
  before do
    @db = connect_db
    @user = session[:user_id] ? query_db('SELECT * FROM user WHERE user_id = ?', [session[:user_id]], true) : nil
  end

  # After request
  after do
    @db.close if @db
  end

  # Routes
  get '/' do
    redirect '/public' unless @user
    @messages = query_db('''
      SELECT message.*, user.* FROM message, user
      WHERE message.flagged = 0 AND message.author_id = user.user_id
      AND (user.user_id = ? OR user.user_id IN (SELECT whom_id FROM follower WHERE who_id = ?))
      ORDER BY message.pub_date DESC LIMIT ?''',
      [@user['user_id'], @user['user_id'], PER_PAGE])
    @title = "My Timeline"
    erb :timeline
  end

  get '/public' do
    @messages = query_db('''
      SELECT message.*, user.* FROM message, user
      WHERE message.flagged = 0 AND message.author_id = user.user_id
      ORDER BY message.pub_date DESC LIMIT ?''', [PER_PAGE])
    @title = "Public Timeline"
    erb :timeline
  end
  
  get '/timeline' do
    @messages = query_db('''
      SELECT message.*, user.* FROM message, user
      WHERE message.flagged = 0 AND message.author_id = user.user_id
      ORDER BY message.pub_date DESC LIMIT ?''', [PER_PAGE])
    @title = "Timeline"
    erb :timeline
  end

  get '/login' do
    @title = "Sign In"
    erb :login
  end

  post '/login' do
    @user = query_db('SELECT * FROM user WHERE username = ?', [params[:username]], true)
    if @user && BCrypt::Password.new(@user['pw_hash']) == params[:password]
      session[:user_id] = @user['user_id']
      flash[:notice] = 'You were logged in'
      redirect '/'
    elsif @user.nil?
      @error = 'Invalid username'
      erb :login
    elsif BCrypt::Password.new(@user['pw_hash']) != params[:password]
      @error = 'Invalid password'
      erb :login
    end
  end

  get '/register' do
    @title = "Sign Up"
    erb :register
  end

  post '/register' do
    @username = params[:username]
    @email = params[:email]
    password = params[:password]
    password2 = params[:password2]
  
    if @username.empty?
      @error = 'You have to enter a username'
      return erb :register
    elsif @email.empty? || !@email.include?('@')
      @error = 'You have to enter a valid email address'
      return erb :register
    elsif password.empty?
      @error = 'You have to enter a password'
      return erb :register
    elsif password != password2
      @error = 'The two passwords do not match'
      return erb :register
    elsif !query_db('SELECT * FROM user WHERE username = ?', [@username], true).nil?
      @error = "Username is already taken."
      return erb :register
    else
      # Store the new user in the database
      password_hash = BCrypt::Password.create(password)
      query_db('INSERT INTO user (username, email, pw_hash) VALUES (?, ?, ?)', [@username, @email, password_hash.to_s])
      # TODO: is not "flashing" this message to the user in the login page
      flash[:notice] = "You were successfully registered and can login now"
      # Redirect to login page after successful registration
      redirect '/login'
    end
  end

  get '/logout' do
    session.clear
    flash[:notice] = "You were logged out"
    redirect '/public'
  end

  get '/:username' do
    @profile_user = query_db('SELECT * FROM user WHERE username = ?', [params[:username]], true)
    halt 404 unless @profile_user
    followed = @user && query_db('SELECT 1 FROM follower WHERE who_id = ? AND whom_id = ?', [@user['user_id'], @profile_user['user_id']], true)
    @messages = query_db('''
      SELECT message.*, user.* FROM message, user
      WHERE user.user_id = message.author_id AND user.user_id = ?
      ORDER BY message.pub_date DESC LIMIT ?''',
      [@profile_user['user_id'], PER_PAGE])
    @title = "#{params[:username]}'s Timeline"
    erb :timeline, locals: { followed: followed }
  end

  post '/add_message' do
    halt 401 unless @user
    if params[:text] && !params[:text].empty?
      query_db('INSERT INTO message (author_id, text, pub_date, flagged) VALUES (?, ?, ?, 0)',
              [@user['user_id'], params[:text], Time.now.to_i])
      
      flash[:notice] = "Your message was recorded"
      redirect '/'
    end
  end

  post '/:username/follow' do
    halt 401 unless @user
    whom_id = get_user_id(params[:username])
    halt 401 unless whom_id
    query_db('INSERT INTO follower (who_id, whom_id) VALUES (?, ?)', [@user['user_id'], whom_id])
    flash[:notice] = "You are now following \"#{params[:username]}\""
    redirect to("/#{params[:username]}/timeline")
  end

  get '/:username/unfollow' do
    halt 401 unless @user
    whom_id = get_user_id(params[:username])
    halt 404 unless whom_id
    query_db('DELETE FROM follower WHERE who_id=? AND whom_id=?', [@user['user_id'], whom_id])
    flash[:notice] = "You are no longer following \"#{params[:username]}\""
    redirect to("/#{params[:username]}/timeline")
  end

  # Start the application
  run! if __FILE__ == $PROGRAM_NAME

end
