module Knockoff
  class ReplicaConnectionPool
    attr_reader :pool

    def initialize(uris)
      @pool = Concurrent::Hash.new

      uris.each_with_index do |uri, index|
        @pool["replica_#{index}"] = connection_class(index, uri)
      end
    end

    def random_replica_connection
      @pool[@pool.keys.sample]
    end

    # Based off of code from replica_pools gem
    # generates a unique ActiveRecord::Base subclass for a single replica
    def connection_class(replica_index, uri)
      class_name = "Replica#{replica_index}"

      # TODO: Hardcoding the uri string feels meh. Either set the database config
      # or reference ENV instead
      Knockoff.module_eval %Q{
        class #{class_name} < ActiveRecord::Base
          self.abstract_class = true
          establish_connection '#{uri}'
        end
      }, __FILE__, __LINE__

      Knockoff.const_get(class_name)
    end
  end
end
