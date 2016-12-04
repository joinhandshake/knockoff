module Knockoff
  class Config
    # The current environment. Normally set to Rails.env, but
    # will default to 'development' outside of Rails apps.
    attr_reader :environment

    # An array of configs to use for the replica pool.
    attr_reader :replica_configs

    # A hash of replica configs to their config hash.
    attr_reader :replicas_configurations

    def initialize
      @environment = 'development'
      @replicas_configurations = {}
      set_replica_configs
    end

    def replica_database_keys
      @replicas_configurations.keys
    end

    def replica_env_keys
      if ENV['KNOCKOFF_REPLICA_ENVS'].nil?
        []
      else
        ENV['KNOCKOFF_REPLICA_ENVS'].split(',').map(&:strip)
      end
    end

    def update_replica_configs(new_configs)
      ActiveRecord::Base.configurations['knockoff_replicas'].merge(new_configs) if ActiveRecord::Base.configurations['knockoff_replicas'].present?
      @replicas_configurations.each do |key, _config|
        update_replica_config(key, new_configs)
      end
    end

    private

    def update_replica_config(key, new_configs)
      @replicas_configurations[key].merge!(new_configs)
      ActiveRecord::Base.configurations[key].merge!(new_configs)
    end

    def set_replica_configs
      @replica_configs ||= parse_knockoff_replica_envs_to_configs
    end

    def parse_knockoff_replica_envs_to_configs
      # As a basic prevention of crashes, attempt to parse each DB uri
      # and don't add the uri to the final list if it can't be parsed
      replica_env_keys.map.with_index(0) do |env_key, index|
        begin
          uri = URI.parse(ENV[env_key])

          # Configure parameters such as prepared_statements, pool, reaping_frequency for all replicas.
          replica_config = ActiveRecord::Base.configurations['knockoff_replicas'] || {}

          adapter =
            if uri.scheme == "postgres"
              'postgresql'
            else
              uri.scheme
            end

          # Base config from the ENV uri. Sqlite is a special case
          # and all others follow 'normal' config
          uri_config =
            if uri.scheme == 'sqlite3'
              {
                'adapter' => adapter,
                'database' => uri.to_s.split(':')[1]
              }
            else
              {
                'adapter' => adapter,
                'database' => (uri.path || "").split("/")[1],
                'username' => uri.user,
                'password' => uri.password,
                'host' => uri.host,
                'port' => uri.port
              }
            end

          # Store the hash in configuration and use it when we establish the connection later.
          key = "knockoff_replica_#{index}"
          full_config = replica_config.merge(uri_config)

          ActiveRecord::Base.configurations[key] = full_config
          @replicas_configurations[key] = full_config
        rescue URI::InvalidURIError
          Rails.logger.info "LOG NOTIFIER: Invalid URL specified in follower_env_keys. Not including URI, which may result in no followers used." # URI is purposely not printed to logs
          # Return a 'nil' which will be removed from
          # configs with `compact`, resulting in no configs and no followers,
          # therefore disabled since this env will not be in environments list.
          nil
        end
      end.compact
    end
  end
end
