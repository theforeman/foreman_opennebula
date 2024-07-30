module FogExtensions
  module OpenNebula
    module Server
      extend ActiveSupport::Concern
      include ActionView::Helpers::NumberHelper

      attr_writer :template_id, :image_id, :disk_size, :vmgroup_id,
        :vmgroup_role, :scheduler_hint_filter, :scheduler_hint_data

      included do
        def cpu
          onevm_object.present? ? onevm_object['TEMPLATE/CPU'] : attributes[:cpu]
        end

        def vcpu
          onevm_object.present? ? onevm_object['TEMPLATE/VCPU'] : attributes[:vcpu]
        end

        def start
          onevm_object.resume
        end

        def stop
          onevm_object.poweroff(true)
        end
      end

      def reboot
        onevm_object.reboot
        true
      end

      def reset
        onevm_object.reboot(true)
        true
      end

      def template_id
        onevm_object.present? ? onevm_object['TEMPLATE/TEMPLATE_ID'] : @template_id
      end

      def vmgroup_id
        onevm_object.present? ? onevm_object['TEMPLATE/VMGROUP/VMGROUP_ID'] : @vmgroup_id
      end

      def vmgroup_role
        onevm_object.present? ? onevm_object['TEMPLATE/VMGROUP/ROLE'] : @vmgroup_role
      end

      def sched_requirements
        return unless onevm_object
        onevm_object['USER_TEMPLATE/SCHED_REQUIREMENTS']
      end

      def scheduler_hint_filter
        if sched_requirements
          case sched_requirements
          when /^CLUSTER_ID = \d+$/
            'Cluster'
          when /^ID = \d+$/
            'Host'
          else
            'Raw'
          end
        else
          @scheduler_hint_filter
        end
      end

      def scheduler_hint_data
        if sched_requirements
          scheduler_hint_filter == 'Raw' ? sched_requirements : sched_requirements[/\d+/]
        else
          @scheduler_hint_data
        end
      end

      def disks
        return if onevm_object.nil?
        [onevm_object.to_hash['VM']['TEMPLATE']['DISK']].flatten.compact.map do |disk|
          OpenStruct.new(disk.transform_keys(&:downcase))
        end
      end

      def image_id
        disks.try(:first).try(:image_id) || @image_id
      end

      def disk_size
        disks.try(:first).try(:size) || @disk_size
      end

      def interfaces
        [onevm_object.to_hash['VM']['TEMPLATE']['NIC']].flatten.compact.map do |nic|
          OpenStruct.new(nic.transform_keys(&:downcase))
        end
      end

      def select_nic(fog_nics, nic)
        fog_nics.detect { |fn| fn.network_id == nic.compute_attributes['vnet'] }
      end

      def host
        onevm_object['HISTORY_RECORDS/HISTORY[last()]/HOSTNAME']
      end

      def sched_message
        onevm_object['USER_TEMPLATE/SCHED_MESSAGE']
      end

      def display
        graphics = onevm_object.to_hash['VM']['TEMPLATE']['GRAPHICS']
        graphics['TYPE'].downcase!
        graphics.transform_keys(&:downcase).symbolize_keys
      end

      def poweroff?
        (status == 8)
      end

      def to_s
        name
      end

      def vm_description
        _('%{cpu} CPU, %{vcpu} VCPU, %{memory} memory and %{disk} disk') % {
          :cpu    => cpu,
          :vcpu   => vcpu,
          :memory => number_to_human_size(memory.to_i.megabytes),
          :disk   => number_to_human_size(disk_size.to_i.megabytes)
        }
      end
    end
  end
end
