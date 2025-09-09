module ForemanOpennebula
  class Opennebula < ComputeResource
    include ForemanOpennebula::KeyPairComputeResource

    validates :url, :format => { :with => URI::DEFAULT_PARSER.make_regexp }, :presence => true
    validates :user, :password, :presence => true

    delegate :flavors, :networks, :to => :client

    def self.provider_friendly_name
      'OpenNebula'
    end

    def self.model_name
      ComputeResource.model_name
    end

    def capabilities
      [:build, :image, :key_pair]
    end

    def provided_attributes
      super.merge({ :mac => :mac })
    end

    def possible_scheduler_hints
      %w[Cluster Host Raw]
    end

    def available_flavors
      # TODO: Sort by name.
      flavors.sort_by { |flavor| flavor.id.to_i }
    end

    def available_networks
      networks.sort_by(&:name)
    end

    def available_images
      image_pool = ::OpenNebula::ImagePool.new(client.client)
      rc = image_pool.info
      raise ::Foreman::Exception.new N_(rc.message) if ::OpenNebula.is_error?(rc)
      image_pool.sort_by(&:name)
    end

    def available_clusters
      cluster_pool = ::OpenNebula::ClusterPool.new(client.client)
      rc = cluster_pool.info
      raise ::Foreman::Exception.new N_(rc.message) if ::OpenNebula.is_error?(rc)
      cluster_pool.sort_by(&:name)
    end

    def available_hosts
      host_pool = ::OpenNebula::HostPool.new(client.client)
      rc = host_pool.info
      raise ::Foreman::Exception.new N_(rc.message) if ::OpenNebula.is_error?(rc)
      host_pool.sort_by(&:name)
    end

    def available_vmgroups
      vmgroup_pool = ::OpenNebula::VMGroupPool.new(client.client)
      rc = vmgroup_pool.info
      raise ::Foreman::Exception.new N_(rc.message) if ::OpenNebula.is_error?(rc)
      vmgroup_pool.sort_by(&:name)
    end

    def available_roles(vmgroup_id)
      available_vmgroups.detect { |vmgroup| vmgroup.id == vmgroup_id.to_i }.role_names.sort
    end

    def available_users
      user_pool = ::OpenNebula::UserPool.new(client.client)
      rc = user_pool.info
      raise ::Foreman::Exception.new N_(rc.message) if ::OpenNebula.is_error?(rc)
      user_pool
    end

    def create_vm(args = {})
      vm_attrs = {:name => args[:name]}
      vm_attrs[:flavor] = flavors.get(args[:template_id])
      vm_attrs[:flavor].template_id = args[:template_id]
      vm_attrs[:flavor].cpu = args[:cpu] if args[:cpu].present?
      vm_attrs[:flavor].vcpu = args[:vcpu] if args[:vcpu].present?
      vm_attrs[:flavor].memory = args[:memory] if args[:memory].present?

      if args[:disk_size].present?
        [vm_attrs[:flavor].disk].flatten.compact.first[:SIZE] = args[:disk_size]
      end

      vm_attrs[:flavor].nic = args[:interfaces_attributes].map do |_, attrs|
        nic = {
          :vnet => networks.get(attrs[:vnet])
        }
        nic[:ip] = attrs['ip'] if args['provision_method'] == 'image' && attrs['ip'].present?
        if vm_attrs[:flavor].nic_default.present?
          vm_attrs[:flavor].nic_default.each do |param, value|
            nic[param.downcase.to_sym] = value
          end
        end
        new_interface(nic)
      end

      if args[:scheduler_hint_filter].present? && args[:scheduler_hint_data].present?
        if args[:scheduler_hint_filter] == 'Cluster'
          cluster = available_clusters.detect { |c| c.id == args[:scheduler_hint_data].to_i }
          vm_attrs[:flavor].sched_requirements = "CLUSTER_ID = #{cluster.id}"
        elsif args[:scheduler_hint_filter] == 'Host'
          host = available_hosts.detect { |h| h.id == args[:scheduler_hint_data].to_i }
          vm_attrs[:flavor].sched_requirements = "ID = #{host.id}"
        else
          vm_attrs[:flavor].sched_requirements = args[:scheduler_hint_data]
        end
      end

      if args[:vmgroup_id].present? && args[:vmgroup_role].present?
        vm_attrs[:flavor].vmgroup = { 'VMGROUP_ID' => args[:vmgroup_id], 'ROLE' => args[:vmgroup_role] }
      end

      if args['provision_method'] == 'image' && args['image_id'].present?
        [vm_attrs[:flavor].disk].flatten.compact.first.delete('IMAGE')
        [vm_attrs[:flavor].disk].flatten.compact.first['IMAGE_ID'] = args[:image_id]

        vm_attrs[:flavor].context['SET_HOSTNAME'] = args[:name]
        vm_attrs[:flavor].context['USER_DATA'] = args[:user_data] if args[:user_data].present?

        vm_attrs[:flavor].os['BOOT'] = 'disk0'
      else
        vm_attrs[:flavor].os['BOOT'] = 'nic0,disk0'
      end

      vm = super(vm_attrs)
      vm.wait_for { vm.status == 1 }
      find_vm_by_uuid(vm.id)
    end

    def vm_ready(vm)
      vm.wait_for { ready? || poweroff? }
      raise Foreman::Exception.new(N_('Failed to run VM %{name}'), { :name => vm.name }) if vm.poweroff?
    end

    def supports_update?
      true
    end

    def update_required?(old_attrs, new_attrs)
      vm = find_vm_by_uuid(old_attrs[:uuid])
      old_attrs[:disk_size] = vm.disk_size
      super(old_attrs, new_attrs)
    end

    def save_vm(uuid, attr)
      vm = find_vm_by_uuid(uuid)
      changed_attrs = %i[cpu vcpu memory].reject { |k| vm.send(k).to_s == attr[k].to_s }

      if !vm.ready? && !vm.poweroff?
        raise ::Foreman::Exception.new N_("The VM status: #{vm.status}. It should be ACTIVE (3) or POWEROFF (8)")
      end

      last_state = vm.state
      if vm.ready?
        vm.onevm_object.poweroff(true)
        vm.wait_for { poweroff? }
      end

      if changed_attrs.any?
        flavor = client.flavors.new
        %i[cpu vcpu memory].each { |k| flavor.send("#{k}=", attr[k].to_s) }
        vm.onevm_object.resize(flavor.to_s, true)

        renewed_vm = find_vm_by_uuid(uuid)
        unchanged_attrs = changed_attrs.reject { |k| renewed_vm.send(k).to_s == attr[k].to_s }
        if unchanged_attrs.any?
          raise ::Foreman::Exception.new N_("Parameter #{unchanged_attrs.join(', ')} was not changed. "\
                                            'Check if the host has enough resources for this VM')
        end
      end

      if vm.disk_size.to_i != attr[:disk_size].to_i
        disk_id = vm.disks.first.disk_id.to_i
        rc = vm.onevm_object.disk_resize(disk_id, attr[:disk_size].to_i)
        raise ::Foreman::Exception.new N_(rc.message) if ::OpenNebula.is_error?(rc)
        sleep(1) # wait before resume vm
      end

      if last_state == 'RUNNING'
        vm.onevm_object.resume
        sleep(2)
        vm_ready(vm)
      end
      vm
    end

    def test_connection(options = {})
      super
      %i[url user password].all? { |i| errors[i].empty? } && !client.client.get_version.is_a?(OpenNebula::Error)
    rescue => e
      errors[:base] << e.message
    end

    def console(uuid)
      vm = find_vm_by_uuid(uuid)
      WsProxy.start(:host => vm.host, :host_port => vm.display[:port],
        :password => vm.display[:password]).merge(:type => vm.display[:type], :name => vm.name)
    end

    def associated_host(vm)
      associate_by('mac', vm.interfaces.map(&:mac))
    end

    def host_interfaces_attrs(host)
      setup_nics_attrs(host)
      super
    end

    private

    def setup_nics_attrs(host)
      host.interfaces.each do |nic|
        nic.compute_attributes['vnet'] = nic.subnet&.opennebula_vnet.to_s
      end
    end

    def client
      @client ||= Fog::Compute.new(
        provider: 'OpenNebula',
        opennebula_username: user,
        opennebula_password: password,
        opennebula_endpoint: url
      )
    end
  end
end
