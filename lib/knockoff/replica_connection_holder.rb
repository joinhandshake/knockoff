module Knockoff
  class ReplicaConnectionHolder < ActiveRecord::Base
    self.abstract_class = true

    attr_accessor :knockoff_uri

    def initialize(knockoff_uri)
      @knockoff_uri = knockoff_uri
      establish_connection(knockoff_uri)
    end
  end
end
