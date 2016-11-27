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
      raise Knockoff::Error.new('on_slave cannot be used inside transaction block!') if inside_transaction?

      if Knockoff.disabled
        :primary
      else
        target
      end
    end

    def inside_transaction?
      open_transactions = run_on(:primary) { ActiveRecord::Base.connection.open_transactions }
      open_transactions > Knockoff.base_transaction_depth
    end

    def run_on(target)
      backup = RequestLocals.fetch(:knockoff) # Save for recursive nested calls
      RequestLocals.store[:knockoff] = target
      yield
    ensure
      RequestLocals.store[:knockoff] = backup
    end
  end
end