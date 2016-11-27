module ActiveRecord
  class Base
    class << self
      alias_method :original_connection, :connection

      def connection
        case RequestLocals.fetch(:knockoff)
        when :replica
          # Grab a random replica connection, and if that returns nothing return original_connection
          knockoff.random_replica_connection.original_connection || original_connection
        when :primary, NilClass
          original_connection
        else
          raise knockoff::Error.new("invalid target: #{RequestLocals.fetch(:knockoff)}")
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
