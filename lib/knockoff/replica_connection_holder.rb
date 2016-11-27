module Knockoff
  class ReplicaConnectionHolder < ActiveRecord::Base
    self.abstract_class = true

    class << self
      # for delayed activation
      def activate
        raise Knockoff::Error, 'Knockoff.spec_key invalid!' unless ActiveRecord::Base.configurations[Knockoff.spec_key]
        establish_connection Knockoff.spec_key.to_sym
      end
    end
  end
end