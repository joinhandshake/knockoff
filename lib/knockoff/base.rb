module Knockoff
  class Base
    attr_reader :target

    def initialize(target, check_transaction: true)
      @target = decide_with(target, check_transaction)
    end

    def run(&block)
      run_on @target, &block
    end

  private

    def decide_with(target, check_transaction)
      calculated_target =
        if Knockoff.enabled
          target
        else
          :primary
        end

      # Don't allow setting the target to anything other than primary if we are already in a transaction
      if calculated_target != :primary && check_transaction && inside_transaction?
        raise Knockoff::Error.new('on_replica cannot be used inside transaction block!')
      end
      calculated_target
    end

    def inside_transaction?
      open_transactions = run_on(:primary) { ::ActiveRecord::Base.connection.open_transactions }
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
