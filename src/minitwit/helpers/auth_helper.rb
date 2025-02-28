module AuthHelper
  # Check API authorization
  def authenticate_api_request
    auth = request.env['HTTP_AUTHORIZATION']
    if auth != 'Basic c2ltdWxhdG9yOnN1cGVyX3NhZmUh'
      halt 403, JSON.generate({ status: 403, 'error_msg': 'You are not authorized to use this resource!' })
    end
  end

  def current_user
    @current_user ||= session[:user_id] ? get_user_by_id(session[:user_id]) : nil
  end
  
  # Register user
  def register_user(username, email, password)
    return { success: false, error: "You have to enter a username" } if username.nil? || username.empty?
    return { success: false, error: "You have to enter a valid email address" } if email.nil? || email.empty? || !email.include?('@')
    return { success: false, error: "You have to enter a password" } if password.nil? || password.empty?
    
    existing_user = get_user_by_username(username)
    return { success: false, error: "Username is already taken." } if existing_user
    
    password_hash = BCrypt::Password.create(password)
    
    # Using Sequel to insert the new user
    db[:user].insert(
      username: username, 
      email: email, 
      pw_hash: password_hash
    )
    
    { success: true }
  end
  
  # Authenticate user
  def authenticate_user(username, password)
    user = get_user_by_username(username)
    
    if user.nil?
      return { success: false, error: 'Invalid username' }
    elsif BCrypt::Password.new(user[:pw_hash]) != password
      return { success: false, error: 'Invalid password' }
    else
      session[:user_id] = user[:user_id]  # Store user ID in session
      return { success: true, user: user }
    end
  end
end