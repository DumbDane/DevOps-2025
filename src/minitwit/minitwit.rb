require 'sinatra/base'
require 'json'
require 'rack-flash'
require 'sqlite3'
require 'bcrypt'
require 'erb'
require 'rack/session/cookie'
require 'securerandom'
require 'digest/md5'
require 'sequel'
require 'dotenv/load'

# Require helpers and controllers
Dir[File.join(__dir__, "helpers/*.rb")].each {|file| require file }
require_relative 'controllers/base_controller'
require_relative 'controllers/web_controller'
require_relative 'controllers/api_controller'

class MiniTwit < Sinatra::Base
  SECRET_KEY = SecureRandom.hex(32)
  PER_PAGE = 30
  DATABASE = {
    'test' => File.join(__dir__, '../test/tmp/mock.db'),
    'dev' =>  File.join(__dir__, 'tmp/minitwit.db'),
    'prod' =>  File.join(__dir__, '/tmp/minitwit.db'),
  }[ENV.fetch('ENV', 'dev')]
  
  configure do
    enable :sessions
    use Rack::Session::Cookie, key: 'rack.session', secret: SECRET_KEY
    use Rack::Flash
  end

  # Mount controllers
  use WebController
  use ApiController
end
