module FogExtensions
  module OpenNebula
    module Interface
      extend ActiveSupport::Concern

      included do
        attribute :ip
      end
    end
  end
end
