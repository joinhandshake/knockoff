require 'spec_helper'

describe Knockoff do
  def knockoff_value
    Thread.current[:knockoff]
  end

  def on_replica?
    knockoff_value == :replica
  end

  it 'enables by configuration' do
    begin
      backup = Knockoff.enabled

      Knockoff.enabled = true
      Knockoff.on_replica { expect(knockoff_value).to be :replica }

      Knockoff.enabled = false
      Knockoff.on_replica { expect(knockoff_value).to be :primary }

    ensure
      Knockoff.enabled = backup
    end
  end

  context 'enabled' do
    before(:each) { Knockoff.enabled = true }

    it 'sets thread local' do
      Knockoff.on_primary { expect(knockoff_value).to be :primary }
      Knockoff.on_replica  { expect(knockoff_value).to be :replica }
    end

    it 'returns value from block' do
      expect(Knockoff.on_primary { User.count }).to be 2
      expect(Knockoff.on_replica  { User.count }).to be 1
    end

    it 'handles nested calls' do
      # Slave -> Slave
      Knockoff.on_replica do
        expect(on_replica?).to be true

        Knockoff.on_replica do
          expect(on_replica?).to be true
        end

        expect(on_replica?).to be true
      end

      # Slave -> Master
      Knockoff.on_replica do
        expect(on_replica?).to be true

        Knockoff.on_primary do
          expect(on_replica?).to be false
        end

        expect(on_replica?).to be true
      end
    end

    context 'allows for setting the default target' do
      after(:each) { Knockoff.instance_variable_set("@default_target", nil) }

      it 'sets the target' do
        expect(Knockoff.default_target).to be nil
        Knockoff.default_target = :replica
        expect(Knockoff.default_target).to eq :replica
        Knockoff.on_primary { expect(on_replica?).to be false }
        expect(Knockoff.default_target).to eq :replica
        Knockoff.default_target = :primary
        expect(Knockoff.default_target).to eq :primary
      end

      it 'returns the correct connection' do
        expect(ActiveRecord::Base.connection).to eq ActiveRecord::Base.original_connection
        Knockoff.default_target = :replica
        expect(ActiveRecord::Base.connection).to eq Knockoff::KnockoffReplica0.connection
        Knockoff.on_primary { expect(ActiveRecord::Base.connection).to eq ActiveRecord::Base.original_connection }
        expect(ActiveRecord::Base.connection).to_not eq ActiveRecord::Base.original_connection
        Knockoff.default_target = :primary
        expect(ActiveRecord::Base.connection).to eq ActiveRecord::Base.original_connection
      end
    end

    context 'in transaction' do
      it 'raises error in transaction if replica is attempted' do
        User.transaction do
          expect { Knockoff.on_replica { User.first } }.to raise_error(Knockoff::Error)
        end
      end

      it 'does not raise error in transaction if primary is redundantly enforced' do
        User.transaction do
          expect { Knockoff.on_primary { User.first } }.not_to raise_error
        end
      end
    end

    it 'avoids stack overflow with 3rdparty gem that defines alias_method. namely newrelic...' do
      class ActiveRecord::Relation
        alias_method :calculate_without_thirdparty, :calculate

        def calculate(*args)
          calculate_without_thirdparty(*args)
        end
      end

      expect(User.count).to be 2

      class ActiveRecord::Relation
        alias_method :calculate, :calculate_without_thirdparty
      end
    end

    it 'works with any scopes' do
      expect(User.count).to be 2
      expect(User.on_replica.count).to be 1

      # Why where(nil)?
      # http://stackoverflow.com/questions/18198963/with-rails-4-model-scoped-is-deprecated-but-model-all-cant-replace-it
      expect(User.where(nil).to_a.size).to be 2
      expect(User.on_replica.where(nil).to_a.size).to be 1
    end

    it '#on_replica and #on_primary work correctly with simple relations' do
      expect(Knockoff.on_primary { User.where(id: [1, 2]).to_a.size }).to be 2
      expect(Knockoff.on_replica { User.where(id: [1, 2]).to_a.size }).to be 1
    end

    it 'can clear active connections on all replicas' do
      Knockoff.clear_all_active_connections!
    end

    it 'defines self.connection_config' do
      expect(Knockoff::KnockoffReplica0.connection_config).not_to be_nil
      expect(Knockoff::KnockoffReplica0.connection_config['adapter']).to eq 'sqlite3'
    end

    context "bad configurations" do
      xit 'connects to primary if list of replicas is malformed' do
        before_value = ENV['KNOCKOFF_REPLICA_ENVS']

        begin
          Knockoff.enabled = true
          expect(Knockoff.on_replica { User.count }).to be 2
        ensure
          ENV['KNOCKOFF_REPLICA_ENVS'] = before_value
        end
      end
    end
  end
end
