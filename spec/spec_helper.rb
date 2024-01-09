require 'rubygems'
require 'bundler/setup'

ENV['RACK_ENV'] = 'test'

require 'knockoff'

ActiveRecord::Base.configurations = ActiveRecord::DatabaseConfigurations.new({
  :test => { :adapter => 'sqlite3', :database => 'tmp/test_db' }
})

# Setup the ENV's for replicas
ENV['KNOCKOFF_REPLICA1'] = 'sqlite3:tmp/test_replica_db'
ENV['KNOCKOFF_REPLICA_ENVS'] = 'KNOCKOFF_REPLICA1'

# Prepare databases
class User < ActiveRecord::Base
end

# Create two records on primary
ActiveRecord::Base.establish_connection(:test)
ActiveRecord::Base.connection.create_table :users, force: true
User.create
User.create

# Create one record on replica, emulating replication lag
ActiveRecord::Base.establish_connection(ENV['KNOCKOFF_REPLICA1'])
ActiveRecord::Base.connection.create_table :users, force: true
User.create

# Reconnect to primary
ActiveRecord::Base.establish_connection(:test)
