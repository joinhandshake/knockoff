module ActiveRecord
  class Relation
    attr_accessor :knockoff_target

    # Supports queries like User.on_slave.to_a
    alias_method :exec_queries_without_knockoff, :exec_queries

    def exec_queries
      if knockoff_target == :slave
        knockoff.on_slave { exec_queries_without_knockoff }
      else
        exec_queries_without_knockoff
      end
    end


    # Supports queries like User.on_slave.count
    alias_method :calculate_without_knockoff, :calculate

    def calculate(*args)
      if knockoff_target == :slave
        knockoff.on_slave { calculate_without_knockoff(*args) }
      else
        calculate_without_knockoff(*args)
      end
    end
  end
end
