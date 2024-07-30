module ForemanOpennebula
  module HostsHelperExtensions
    extend ActiveSupport::Concern

    included do
      def provider_partial_exist?(compute_resource, partial)
        return false unless compute_resource

        compute_resource_name = compute_resource.provider.downcase

        return false if controller_name == 'compute_attributes' &&
          compute_resource_name == 'opennebula' && partial == 'network'

        ActionController::Base.view_paths.any? do |path|
          File.exist?(File.join(path, 'compute_resources_vms', 'form', compute_resource_name, "_#{partial}.html.erb"))
        end
      end
    end
  end
end
