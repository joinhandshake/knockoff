require 'spec_helper'

describe Knockoff do
  def knockoff_value
    RequestLocals.fetch(:knockoff) { nil }
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

    it 'raises error in transaction' do
      User.transaction do
        expect { Knockoff.on_replica { User.first } }.to raise_error(Knockoff::Error)
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