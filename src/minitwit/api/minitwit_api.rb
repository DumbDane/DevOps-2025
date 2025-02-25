require 'sinatra/base'
require 'json'
require 'sqlite3'
require 'bcrypt'
require 'rack/session/cookie'
require 'securerandom'

class MiniTwit < Sinatra::Base
  SECRET_KEY = SecureRandom.hex(32)
  PER_PAGE = 30
  DATABASE = '../db/minitwit.db'
  
  # Configure session management inside a configure block
  configure do
    enable :sessions
    use Rack::Session::Cookie, key: 'rack.session', secret: SECRET_KEY
  end


  # Before request
  before do
    @db = connect_db(DATABASE)
    #ph = BCrypt::Password.create(params[:pwd]).to_s
    #@user = query_db('SELECT * FROM user WHERE username = ? AND pw_hash = ?', [params[:username], ph], true)

    # Parse JSON request body
    begin
      content_type :json
      request.body.rewind

      @latest = params[:latest]
      @data = JSON.parse(request.body.read)
    rescue JSON::ParserError
      status 401
      body JSON({ 'error': 'InvalidJSON', 'message': 'Invalid JSON format' })
    end
  end

  # After request
  after do
    if !@latest.nil?
      file_path = File.join(File.dirname(__FILE__), 'routes/latest_processed_sim_action_id.txt')
      File.write(file_path, @latest)
    end

    @db.close if @db
  end

  # Note that 'helpers' is sinatra way of naming 'utils'
  require_relative 'helpers/init'
  require_relative 'routes/init'

  # Start the application
  run! if __FILE__ == $PROGRAM_NAME

end
