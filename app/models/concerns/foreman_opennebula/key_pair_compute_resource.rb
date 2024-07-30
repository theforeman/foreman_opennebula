module ForemanOpennebula
  module KeyPairComputeResource
    extend ActiveSupport::Concern

    included do
      prepend KeyPairCapabilities
      has_one :key_pair, :foreign_key => :compute_resource_id, :dependent => :destroy
      after_create :setup_key_pair
      after_destroy :destroy_key_pair
    end

    def key_pairs
      opennebula_user = available_users.detect { |u| u.name == user }
      public_key = opennebula_user['TEMPLATE/SSH_PUBLIC_KEY']
      return unless public_key.present? && SSHKey.valid_ssh_public_key?(public_key)
      [public_key]
    end

    def get_compute_key_pairs
      return [] unless capabilities.include?(:key_pair)
      active_key = key_pair
      return [] if key_pairs.nil? || active_key.nil?
      akey = SSHKey.new(active_key.secret)
      key_pairs.map do |key|
        key_fingerprint = SSHKey.fingerprint(key)
        key_name = key_fingerprint == akey.md5_fingerprint ? active_key.name : 'unknown'
        ComputeResourceKeyPair.new(key_name, key_fingerprint, active_key.name, active_key.id)
      end
    end

    def recreate
      destroy_key_pair
      setup_key_pair
    end

    def delete_key_from_resource(remote_key_pair = key_pair.name)
      logger.info "removing key from compute resource #{name} "\
                  "(#{provider_friendly_name}): #{remote_key_pair}"
      opennebula_user = available_users.detect { |u| u.name == user }
      template_hash = opennebula_user.to_hash['USER']['TEMPLATE']
      template_hash.delete('SSH_PUBLIC_KEY')
      template_str = template_hash.map { |k, v| "#{k}=\"#{v}\"" }.join("\n")
      opennebula_user.update(template_str)
      KeyPair.destroy_by :compute_resource_id => id
    rescue => e
      Foreman::Logging.exception(
        "Failed to delete key pair from #{provider_friendly_name}: #{name}, you "\
        "might need to cleanup manually: #{e}",
        e,
        :level => :warn
      )
    end

    private

    def setup_key_pair
      key = SSHKey.generate(comment: "foreman-#{id}#{Foreman.uuid}")
      opennebula_user = available_users.detect { |u| u.name == user }
      template_hash = opennebula_user.to_hash['USER']['TEMPLATE']
      template_hash['SSH_PUBLIC_KEY'] = key.ssh_public_key
      template_str = template_hash.map { |k, v| "#{k}=\"#{v}\"" }.join("\n")
      opennebula_user.update(template_str)
      KeyPair.create! :name => key.comment, :compute_resource_id => id, :secret => key.private_key
    rescue => e
      Foreman::Logging.exception('Failed to generate key pair', e)
      destroy_key_pair
      raise
    end

    def destroy_key_pair
      return unless key_pair.present?
      delete_key_from_resource
      # If the key pair could not be removed, it will be logged.
      # Returning 'true' allows this method to not halt the deletion
      # of the Compute Resource even if the key pair could not be
      # deleted for some reason (permissions, not found, etc...)
      true
    end
  end
end
