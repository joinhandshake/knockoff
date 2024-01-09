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

      if !properly_configured? && Knockoff.enabled
        puts "[Knockoff] WARNING: Detected enabled Knockoff without proper replica pool configuration. Setting Knockoff.enabled to false."
        Knockoff.enabled = false
      end
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
      if ActiveRecord::Base.configurations.configs_for(env_name: 'knockoff_replicas').present?
        new_configs.symbolize_keys!.merge!(ActiveRecord::Base.configurations.configs_for(env_name: 'knockoff_replicas').first.configuration_hash)
      end

      @replicas_configurations.each do |key, _config|
        update_replica_config(key, new_configs)
      end
    end

    # If replica_configs actually containts some configuration information, then
    # we know it was properly configured. Improper URI's will be ignored during the
    # initialization step.
    def properly_configured?
      !@replica_configs.empty?
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
          replica_config = ActiveRecord::Base.configurations.configs_for(env_name: 'knockoff_replicas')&.first || {}

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
          # TODO: In ActiveRecord >= 6, this is a deprecated way to set a configuration. However
          # there appears to be an issue when calling `ActiveRecord::Base.configurations.to_h` in
          # version 6.0.4.8 where
          # multi-database setup is being ignored / dropped. For example if a database.yml setup
          # has something like..
          #
          # development:
          #   primary:
          #     ...
          #   other:
          #     ...
          #
          # then the 'other' database configuration is being dropped.
          key = "knockoff_replica_#{index}"
          config = replica_config.symbolize_keys.merge(uri_config)
          env_name = ActiveRecord::Base.configurations.configurations.first.env_name
          new_config = ActiveRecord::DatabaseConfigurations::HashConfig.new(env_name, key, config)
          ActiveRecord::Base.configurations.configurations << new_config

          @replicas_configurations[key] = config
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
