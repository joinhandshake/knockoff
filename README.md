# Knockoff

[![Build Status](https://github.com/github/docs/actions/workflows/main.yml/badge.svg?branch=main)](https://github.com/joinhandshake/knockoff/actions)
[![Gem Version](https://badge.fury.io/rb/knockoff.svg)](https://badge.fury.io/rb/knockoff)

A gem for easily using read replicas.

:handshake: Battle tested at [Handshake](https://joinhandshake.com/)

## Library Goals

* Minimal ActiveRecord monkey-patching
* Easy run-time configuration using ENV variables
* Opt-in usage of replicas
* No need to change code when adding/removing replicas
* Be thread safe

## Supported Versions

Knockoff supports Rails 4, 5 and 6

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'knockoff'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install knockoff

## Usage

### Initializer

Add an initializer at config/knockoff.rb with the below contents

```
Knockoff.enabled = true # NOTE: Consider adding ENV based disabling
```

### Configuration

Configuration is done using ENV properties. This makes it easy to add and remove replicas at runtime (or to fully disable if needed). First, set up ENV variables pointing to your replica databases. Consider using the [dotenv](https://github.com/bkeepers/dotenv) gem for manging ENV variables.

```
# .env

REPLICA_1=postgres://username:password@localhost:5432/database_name
```

The second ENV variable to set is `KNOCKOFF_REPLICA_ENVS` which is a comma-separated list of ENVS holding database URLs to use as replicas. In this case, the ENV would be set as follows.

```
# .env

KNOCKOFF_REPLICA_ENVS=REPLICA_1
```

Note that it can be multiple replicas, and `knockoff` will use both evenly:

```
KNOCKOFF_REPLICA_ENVS=REPLICA_1,REPLICA_2
```

Lastly, knockoff will read the `'knockoff_replicas'` database.yml config for specifying additional params:

```
# database.yml

knockoff_replicas:
  <<: *common
  prepared_statements: false
```

### Basics

To use one of the replica databases, use

```
Knockoff.on_replica { User.count }
```

To force primary, use

```
Knockoff.on_primary { User.create(name: 'Bob') }
```

### Using in Controllers

A common use case is to use replicas for GET requests and otherwise use primary. A simplified use case might look something like this:

```
# application_controller.rb

around_action :choose_database

def choose_database(&block)
  if should_use_primary_database?
    Knockoff.on_primary(&block)
  else
    Knockoff.on_replica(&block)
  end
end

def should_use_primary_database?
  request.method_symbol != :get
end

```

#### Replication Lag

Replicas will often be slightly behind the primary database. To compensate, consider "sticking" a user who has recently made changes to the primary for a small duration of time to the primary database. This will avoid cases where a user creates a record on primary, is redirected to view that record, and receives a 404 error since the record is not yet in the replica. A simple implementation for this could look like:

```
# application_record.rb

after_commit :track_commit_occurred_in_request

# If any commit happens in a request, we record that and have the logged_in_user
# read from primary for a short period of time.
def track_commit_occurred_in_request
  RequestLocals.store['commit_occurred_in_current_request'] = true
end

# application_controller.rb

after_action :force_leader_if_commit

def force_leader_if_commit
  if RequestLocals.store['commit_occurred_in_current_request'].to_b
    session[:use_leader_until] = Time.current + FORCE_PRIMARY_DURATION
  end
end

```

Then, in your `should_use_primary_database?` method, consult `session[:use_leader_until]` for the decision.

### Run-time Configuration

Knockoff can be configured during runtime. This is done through the `establish_new_connections!` method which takes in a hash of new configurations to apply to each replica before re-connecting.

```
Knockoff.establish_new_connections!({ 'pool' => db_pool })
```

For example, to specify a puma connection pool at bootup your code might look something like

```
# puma.rb

db_pool = Integer(ENV['PUMA_WORKER_DB_POOL'] || threads_count)
# Configure the database connection to have the new pool size and re-establish connection
database_config = ActiveRecord::Base.configurations[Rails.env] || Rails.application.config.database_configuration[Rails.env]
database_config['pool'] = db_pool
ActiveRecord::Base.establish_connection(database_config)
Knockoff.establish_new_connections!({ 'pool' => db_pool })

```

#### Forking

For forking servers, you may disconnect all replicas before forking with `Knockoff.disconnect_all!`.

```
# puma.rb

before_fork do
  ActiveRecord::Base.connection_pool.disconnect!
  Knockoff.disconnect_all!
end
```

### Other Cases

There are likely other cases specific to each application where it makes sense to force primary database and avoid replication lag. Good candidates are time-based pages (a live calendar, for example), forms, and payments.

## Usage Notes

* Do not use prepared statements with this gem

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/joinhandshake/knockoff.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

