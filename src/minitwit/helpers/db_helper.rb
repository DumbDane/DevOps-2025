module DbHelper
  # Database connection helper with Sequel
  def self.db
    @db ||= Sequel.sqlite(MiniTwit::DATABASE)
  end

  # Instance method to access the class methods
  def db
    DbHelper.db
  end

  # Get user ID by username
  def get_user_id(username)
    user = db[:user].where(username: username).first
    user ? user[:user_id] : nil
  end
  
  # Get user by ID
  def get_user_by_id(user_id)
    db[:user].where(user_id: user_id).first
  end
  
  # Get user by username
  def get_user_by_username(username)
    db[:user].where(username: username).first
  end
  
  # Get timeline messages for a user (including messages from users they follow)
  def get_timeline_messages(user_id, limit = MiniTwit::PER_PAGE)
    db[:message]
    .join(:user, user_id: :author_id)
    .where(flagged: 0)
    .where(Sequel.|(
      { Sequel.qualify(:user, :user_id) => user_id },
      { Sequel.qualify(:user, :user_id) => db[:follower].where(who_id: user_id).select(:whom_id) }
    ))
    .order(Sequel.desc(:pub_date))
    .limit(limit)
    .all
  end
  
  # Get public timeline messages
  def get_public_messages(limit = MiniTwit::PER_PAGE)
    db[:message]
      .join(:user, user_id: :author_id)
      .where(flagged: 0)
      .order(Sequel.desc(:pub_date))
      .limit(limit)
      .all
  end
  
  # Get user timeline messages
  def get_user_messages(user_id, limit = MiniTwit::PER_PAGE)
    db[:message]
      .join(:user, user_id: :author_id)
      .where(user_id: user_id)
      .order(Sequel.desc(:pub_date))
      .limit(limit)
      .select_all(:message, :user)
      .all
  end
  
  # Check if one user is following another
  def is_following?(who_id, whom_id)
    db[:follower].where(who_id: who_id, whom_id: whom_id).count > 0
  end
  
  # Add a new message
  def add_message(user_id, text)
    db[:message].insert(
      author_id: user_id,
      text: text,
      pub_date: Time.now.to_i,
      flagged: 0
    )
  end
  
  # Follow a user
  def follow_user(who_id, whom_id)
    db[:follower].insert(who_id: who_id, whom_id: whom_id)
  end
  
  # Unfollow a user
  def unfollow_user(who_id, whom_id)
    db[:follower].where(who_id: who_id, whom_id: whom_id).delete
  end
  
  # Get a list of followers (returns an array of usernames)
  def get_followers(user_id, limit = 100)
    db[:user]
      .join(:follower, whom_id: :user_id)
      .where(who_id: user_id)
      .limit(limit)
      .select(:username)
      .map(:username)
  end

  # Close the database connection
  def self.close_db
    db.disconnect
    @db = nil
  end

  def close_db
    DbHelper.close_db
  end
end