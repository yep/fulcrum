if Rails.env.development?
  # Create a user

  user = User.create! :name => 'Test User', :initials => 'TU',
                      :email => 'test@example.com', :password => 'testpass'
  user.confirm!

  project = Project.create! :name => 'Test Project', :users => [user], :start_date => Time.now
end
