module FogExtensions
  module OpenNebula
    module Flavor
      extend ActiveSupport::Concern

      included do
        attribute :cpu_model
        attribute :nic_default
        attribute :pci
        attribute :vmgroup
        attribute :template_id

        # rubocop:disable Style/StringConcatenation
        def to_s
          '' + get_cpu \
            + get_vcpu \
            + get_memory \
            + get_disk \
            + get_nic \
            + get_os \
            + get_graphics \
            + get_pci \
            + get_raw \
            + get_sched_requirements \
            + get_sched_ds_requirements \
            + get_sched_rank \
            + get_sched_ds_rank \
            + get_context \
            + get_user_variables \
            + get_cpu_model \
            + get_nic_default \
            + get_vmgroup \
            + get_template_id
        end
        # rubocop:enable Style/StringConcatenation

        def get_cpu_model
          return '' unless attributes[:cpu_model]

          ret = "CPU_MODEL=#{attributes[:cpu_model]}\n"
          ret.tr!('{', '[')
          ret.tr!('}', ']')
          ret.delete!('>')
          ret
        end

        def get_nic_default
          return '' unless attributes[:nic_default]

          ret = "NIC_DEFAULT=#{attributes[:nic_default]}\n"
          ret.tr!('{', '[')
          ret.tr!('}', ']')
          ret.delete!('>')
          ret
        end

        def get_vmgroup
          return '' unless attributes[:vmgroup]

          ret = "VMGROUP=#{attributes[:vmgroup]}\n"
          ret.tr!('{', '[')
          ret.tr!('}', ']')
          ret.delete!('>')
          ret
        end

        def get_template_id
          return '' unless attributes[:template_id]

          ret = "TEMPLATE_ID=#{attributes[:template_id]}\n"
          ret.tr!('{', '[')
          ret.tr!('}', ']')
          ret.delete!('>')
          ret
        end

        def get_nic
          return '' if nic.nil?

          ret = ''
          if nic.is_a? Array
            nic.each do |n|
              next if n.vnet.nil?
              val = [%(MODEL="#{n.model}"), %(NETWORK_ID="#{n.vnet.id}")]
              val << %(IP="#{n.ip}") if n.ip.present?
              ret += %(NIC=[#{val.join(',')}]\n)
            end
          end
          ret
        end

        def get_pci
          return '' unless attributes[:pci]

          ret = ''
          if attributes[:pci].is_a? Array
            attributes[:pci].each do |pci|
              ret += "PCI=#{pci}\n"
            end
          else
            ret = "PCI=#{attributes[:pci]}\n"
          end
          ret.tr!('{', '[')
          ret.tr!('}', ']')
          ret.delete!('>')
          ret
        end
      end
    end
  end
end
