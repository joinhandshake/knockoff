module ActiveRecord
  class Base
    class << self
      alias_method :original_connection, :connection

      def connection
        target = Thread.current[:knockoff] || Knockoff.target
        case target
        when :replica
          # Attempts to use a random replica connection, but otherwise falls back to primary
          Knockoff.replica_pool.random_replica_connection.original_connection
        when :primary, NilClass
          original_connection
        else
          raise Knockoff::Error, "Invalid target: #{Thread.current[:knockoff]}"
        end
      end

      # Generate scope at top level e.g. User.on_replica
      def on_replica
        # Why where(nil)?
        # http://stackoverflow.com/questions/18198963/with-rails-4-model-scoped-is-deprecated-but-model-all-cant-replace-it
        context = where(nil)
        context.knockoff_target = :replica
        context
      end
    end
  end
end
