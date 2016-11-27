module ActiveRecord
  class Relation
    attr_accessor :knockoff_target

    # Supports queries like User.on_replica.to_a
    alias_method :exec_queries_without_knockoff, :exec_queries

    def exec_queries
      if knockoff_target == :replica
        knockoff.on_replica { exec_queries_without_knockoff }
      else
        exec_queries_without_knockoff
      end
    end


    # Supports queries like User.on_replica.count
    alias_method :calculate_without_knockoff, :calculate

    def calculate(*args)
      if knockoff_target == :replica
        knockoff.on_replica { calculate_without_knockoff(*args) }
      else
        calculate_without_knockoff(*args)
      end
    end
  end
end
