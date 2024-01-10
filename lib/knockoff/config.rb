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
        updated_config = new_configs.deep_dup.merge!(ActiveRecord::Base.configurations.configs_for(env_name: 'knockoff_replicas').first.config)
      end

      @replicas_configurations.each do |key, _config|
        update_replica_config(key, updated_config)
      end
    end

    # If replica_configs actually containts some configuration information, then
    # we know it was properly configured. Improper URI's will be ignored during the
    # initialization step.
    def properly_configured?
      !@replica_configs.empty?
    end

    private

    def update_replica_config(key, updated_config)
      merged_config = @replicas_configurations[key].config.deep_dup.merge!(updated_config)
      @replicas_configurations[key] = ActiveRecord::DatabaseConfigurations::HashConfig.new(key, key, merged_config)
      ActiveRecord::Base.configurations.configurations << @replicas_configurations[key]
    end

    def set_replica_configs
      @replica_configs ||= parse_knockoff_replica_envs_to_configs
    end

    def parse_knockoff_replica_envs_to_configs
      # As a basic prevention of crashes, attempt to parse each DB uri
      # and don't add the uri to the final list if it can't be parsed
      replica_env_keys.map.with_index(0) do |env_key, index|
        begin

          # Configure parameters such as prepared_statements, pool, reaping_frequency for all replicas.
          to_copy = ActiveRecord::Base.configurations.configs_for(env_name: 'knockoff_replicas')&.first&.config || {}
          register_replica_copy(index, env_key, to_copy)

        rescue URI::InvalidURIError
          Rails.logger.info "LOG NOTIFIER: Invalid URL specified in follower_env_keys. Not including URI, which may result in no followers used." # URI is purposely not printed to logs
          # Return a 'nil' which will be removed from
          # configs with `compact`, resulting in no configs and no followers,
          # therefore disabled since this env will not be in environments list.
          nil
        end
      end.compact
    end

    def register_replica_copy(index, env_key, configuration_hash)
      key = "knockoff_replica_#{index}"
      new_config = create_replica_copy(env_key, key, configuration_hash.deep_dup)
      ActiveRecord::Base.configurations.configurations << new_config
      @replicas_configurations[key] = new_config
    end

    def create_replica_copy(env_key, key, replica_config_hash)
      uri = URI.parse(ENV[env_key])

      replica_config_hash[:adapter] =
        if uri.scheme == "postgres"
          'postgresql'
        else
          uri.scheme
        end

      if uri.scheme == 'sqlite3'
        replica_config_hash[:database] = uri.to_s.split(':')[1]
      else
        replica_config_hash[:database] = (uri.path || "").split("/")[1]
        replica_config_hash[:username] = uri.user
        replica_config_hash[:password] = uri.password
        replica_config_hash[:host] = uri.host
        replica_config_hash[:port] = uri.port
      end

      ActiveRecord::DatabaseConfigurations::HashConfig.new(key, key, replica_config_hash)
    end
  end
end
