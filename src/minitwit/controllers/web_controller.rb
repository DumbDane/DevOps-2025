class WebController < BaseController

  # Index route
  get '/' do
    redirect '/public' unless current_user
    @messages = get_timeline_messages(current_user[:user_id])
    @title = "My Timeline"
    erb :timeline
  end

  # Public timeline
  get '/public' do
    @messages = get_public_messages
    @title = "Public Timeline"
    erb :timeline
  end
  
  # Sign in page
  get '/login' do
    @title = "Sign In"
    erb :login
  end

  # Redirect to login page
  post '/login' do
    result = authenticate_user(params[:username], params[:password])
    
    if result[:success]
      session[:user_id] = result[:user][:user_id]
      flash[:notice] = 'You were logged in'
      redirect '/'
    else
      @error = result[:error]
      erb :login
    end
  end
  
  # Redirect to register page
  get '/register' do
    @title = "Sign Up"
    erb :register
  end

  # Create a new user with credentials
  post '/register' do
    if params[:password] != params[:password2]
      @error = "The two passwords do not match"
      @username = params[:username]
      @email = params[:email]
      return erb :register
    end

    result = register_user(params[:username], params[:email], params[:password])
    
    if result[:success]
      flash[:notice] = "You were successfully registered and can login now"
      redirect '/login'
    else
      @error = result[:error]
      @username = params[:username]
      @email = params[:email]
      erb :register
    end
  end
  
  # Sign out user
  get '/logout' do
    session.clear
    flash[:notice] = "You were logged out"
    redirect '/public'
  end
  
  # Create a new message
  post '/add_message' do
    halt 401 unless current_user
    
    if params[:text] && !params[:text].empty?
      add_message(current_user[:user_id], params[:text])
      flash[:notice] = "Your message was recorded"
    end
    
    redirect '/'
  end

  # Get user page
  get '/:username' do
    @profile_user = get_user_by_username(params[:username])
    halt 404 unless @profile_user
    
    followed = false
    if current_user
      followed = is_following?(current_user[:user_id], @profile_user[:user_id])
    end
    
    @messages = get_user_messages(@profile_user[:user_id])
    @title = "#{params[:username]}'s Timeline"
    erb :timeline, locals: { followed: followed }
  end
  
  # Follow a user
  def follow()
    halt 401, "Unauthorized" unless current_user
    
    whom_id = get_user_id(params[:username])
    halt 404, "User not found" unless whom_id
    
    follow_user(current_user[:user_id], whom_id)
    flash[:notice] = "You are now following \"#{params[:username]}\""
    redirect "/#{params[:username]}"
  end

  get '/:username/follow' do
    follow
  end

  post '/:username/follow' do
    follow
  end
  
  # Unfollow a user
  def unfollow()
    halt 401, "Unauthorized" unless current_user
    
    whom_id = get_user_id(params[:username])
    halt 404, "User not found" unless whom_id
    
    unfollow_user(current_user[:user_id], whom_id)
    flash[:notice] = "You are no longer following \"#{params[:username]}\""
    redirect "/#{params[:username]}"
  end

  get '/:username/unfollow' do
    unfollow
  end

  post '/:username/unfollow' do
    unfollow
  end
end