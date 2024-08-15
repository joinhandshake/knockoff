module Knockoff
  class ReplicaConnectionPool
    attr_reader :pool

    def initialize(config_keys)
      @pool = Concurrent::Hash.new

      config_keys.each do |config_key|
        @pool[config_key] = connection_class(config_key)
      end
    end

    def clear_all_active_connections!
      @pool.each do |_name, klass|
        klass.clear_active_connections!
      end
    end

    def disconnect_all_replicas!
      @pool.each do |_name, klass|
        klass.connection.disconnect!
      end
    end

    # Assumes that the config has been updated to something new, and
    # simply reconnects with the config.
    def reconnect_all_replicas!
      @pool.each do |database_key, klass|
        klass.establish_connection database_key.to_sym
      end
    end

    def set_schema_cache(cache)
      @pool.each do |_name, klass|
        klass.connection_pool.schema_cache = cache
      end
    end

    def random_replica_connection
      @pool[@pool.keys.sample]
    end

    # Based off of code from replica_pools gem
    # generates a unique ActiveRecord::Base subclass for a single replica
    def connection_class(config_key)
      # Config key is of schema 'knockoff_replica_n'
      class_name = "KnockoffReplica#{config_key.split('_').last}"

      # TODO: Hardcoding the uri string feels meh. Either set the database config
      # or reference ENV instead
      Knockoff.module_eval %Q{
        class #{class_name} < ::ActiveRecord::Base
          self.abstract_class = true
          establish_connection :#{config_key}
          def self.connection_db_config
            configurations.find_db_config #{config_key.to_s.inspect}
          end
        end
      }, __FILE__, __LINE__

      Knockoff.const_get(class_name)
    end
  end
end
