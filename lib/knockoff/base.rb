module Knockoff
  class Base
    def initialize(target)
      @target = decide_with(target)
    end

    def run(&block)
      run_on @target, &block
    end

  private

    def decide_with(target)
      calculated_target =
        if Knockoff.enabled
          target
        else
          :primary
        end

      # Don't allow setting the target to anything other than primary if we are already in a transaction
      raise Knockoff::Error.new('on_replica cannot be used inside transaction block!') if calculated_target != :primary && inside_transaction?
      calculated_target
    end

    def inside_transaction?
      open_transactions = run_on(:primary) { ActiveRecord::Base.connection.open_transactions }
      open_transactions > Knockoff.base_transaction_depth
    end

    def run_on(target)
      backup = Thread.current[:knockoff] # Save for recursive nested calls
      Thread.current[:knockoff] = target
      yield
    ensure
      Thread.current[:knockoff] = backup
    end
  end
end
