module ActiveRecord
  class Base
    class << self
      alias_method :connection_without_knockoff, :connection

      def connection
        case Thread.current[:knockoff]
        when :replica
          knockoff.replica_connection_holder.connection_without_knockoff
        when :primary, NilClass
          connection_without_knockoff
        else
          raise knockoff::Error.new("invalid target: #{Thread.current[:knockoff]}")
        end
      end
    end
  end
end
