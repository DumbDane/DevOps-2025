require 'sinatra'

class MiniTwit < Sinatra::Base

  post '/fllws/:username' do
    content_type :json
    req = req_from_sim(request)
    return req unless req.nil?

    # halt 401, "Unauthorized" unless @user

    who_username = params[:username]
    who_id = get_user_id(who_username)
    whom_username = @data['follow'] || @data['unfollow']
    whom_id = get_user_id(whom_username)
    if who_id.nil? || whom_id.nil?
      status 404
      body JSON({ 'message': "User not found" })
    end

      
    if @data.key?('unfollow')
      query_db('DELETE FROM follower WHERE who_id = ? AND whom_id = ?', [who_id, whom_id])
      status 200
      body JSON({ 'message': 'Unfollowed ' + whom_username })
    elsif @data.key?('follow')
      query_db('INSERT INTO follower (who_id, whom_id) VALUES (?, ?)', [who_id, whom_id])
      status 200
      body JSON({ 'message': 'Followed ' + whom_username,  })
    end
  end


  get '/fllws/:username' do
    req = req_from_sim(request)
    return req unless req.nil?

    no_followers = params[:no] || 100
    username = params[:username]
    id = get_user_id(username)

    followers = query_db('SELECT u.username FROM user u
            INNER JOIN follower f on f.whom_id=u.user_id
            WHERE f.who_id = ?
            LIMIT ?', [id, no_followers])
    follower_names = followers.map{|x| x['username']}
    status 200
    body JSON({'follows': follower_names})
  end 

end
