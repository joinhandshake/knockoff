require 'active_record'
require 'knockoff/version'
require 'knockoff/base'
require 'knockoff/config'
require 'knockoff/error'
require 'knockoff/replica_connection_pool'
require 'knockoff/active_record/base'
require 'knockoff/active_record/relation'

module Knockoff
  class << self
    attr_accessor :enabled
    attr_reader :default_target

    def on_replica(check_transaction: true, &block)
      Base.new(:replica, check_transaction: check_transaction).run(&block)
    end

    def on_primary(&block)
      Base.new(:primary).run(&block)
    end

    def default_target=(target)
      @default_target = Base.new(target).target
    end

    def replica_pool
      @replica_pool ||= ReplicaConnectionPool.new(config.replica_database_keys)
    end

    def clear_all_active_connections!
      replica_pool.clear_all_active_connections!
    end

    # Iterates through the replica pool and calls disconnect on each one's connection.
    def disconnect_all!
      replica_pool.disconnect_all_replicas!
    end

    # Updates the config (both internal representation and the ActiveRecord::Base.configuration)
    # with the new config, and then reconnects each replica connection in the replica
    # pool.
    def establish_new_connections!(new_config)
      config.update_replica_configs(new_config)
      replica_pool.reconnect_all_replicas!
    end

    def config
      @config ||= Config.new
    end

    def base_transaction_depth
      @base_transaction_depth ||= begin
        testcase = ActiveSupport::TestCase
        if defined?(testcase) &&
            testcase.respond_to?(:use_transactional_fixtures) &&
            testcase.try(:use_transactional_fixtures)
          1
        else
          0
        end
      end
    end
  end
end
