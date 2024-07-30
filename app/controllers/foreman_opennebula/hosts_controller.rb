module ForemanOpennebula
  class HostsController < ::HostsController
    before_action :ajax_request, :only => [:vmgroup_selected, :scheduler_hint_filter_selected]

    def vmgroup_selected
      return not_found unless params[:host]
      refresh_host
      Taxonomy.as_taxonomy @organization, @location do
        render :partial => 'compute_resources_vms/form/opennebula/vmgroup_role'
      end
    end

    def scheduler_hint_filter_selected
      return not_found unless params[:host]
      refresh_host
      Taxonomy.as_taxonomy @organization, @location do
        render :partial => 'compute_resources_vms/form/opennebula/scheduler_hint_data'
      end
    end
  end
end
