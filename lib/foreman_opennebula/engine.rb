require 'fast_gettext'
require 'gettext_i18n_rails'
require 'fog/opennebula'

module ForemanOpennebula
  class Engine < ::Rails::Engine
    isolate_namespace ForemanOpennebula
    engine_name 'foreman_opennebula'

    initializer 'foreman_opennebula.register_gettext', after: :load_config_initializers do |_app|
      locale_dir = File.join(File.expand_path('../..', __dir__), 'locale')
      locale_domain = 'foreman_opennebula'
      Foreman::Gettext::Support.add_text_domain locale_domain, locale_dir
    end

    initializer 'foreman_opennebula.register_plugin', :before => :finisher_hook do |_app|
      Foreman::Plugin.register :foreman_opennebula do
        requires_foreman '>= 3.7'
        compute_resource ForemanOpennebula::Opennebula
        register_global_js_file 'global'
      end
    end

    config.to_prepare do
      require 'fog/opennebula/models/compute/server'
      require 'fog/opennebula/models/compute/flavor'
      require 'fog/opennebula/models/compute/interface'
      require File.expand_path('../../app/models/concerns/fog_extensions/opennebula/server', __dir__)
      require File.expand_path('../../app/models/concerns/fog_extensions/opennebula/flavor', __dir__)
      require File.expand_path('../../app/models/concerns/fog_extensions/opennebula/interface', __dir__)
      require File.expand_path('../../app/helpers/concerns/foreman_opennebula/hosts_helper_extensions', __dir__)
      require File.expand_path('../../app/helpers/concerns/foreman_opennebula/form_helper_extensions', __dir__)

      ::Fog::Compute::OpenNebula::Server.include(FogExtensions::OpenNebula::Server)
      ::Fog::Compute::OpenNebula::Flavor.include(FogExtensions::OpenNebula::Flavor)
      ::Fog::Compute::OpenNebula::Interface.include(FogExtensions::OpenNebula::Interface)
      ::HostsHelper.include(ForemanOpennebula::HostsHelperExtensions)
      # ::FormHelper.include(ForemanOpennebula::FormHelperExtensions)
      ::ActionView::Base.include(ForemanOpennebula::FormHelperExtensions)
    rescue => e
      Rails.logger.warn "ForemanOpennebula: skipping engine hook (#{e})"
    end

    assets_to_precompile =
      Dir.chdir(root) do
        Dir['app/assets/javascripts/**/*', 'app/assets/stylesheets/**/*'].map do |f|
          f.split(File::SEPARATOR, 4).last
        end
      end

    initializer 'foreman_opennebula.assets.precompile' do |app|
      app.config.assets.precompile += assets_to_precompile
    end

    initializer 'foreman_opennebula.configure_assets', group: :assets do
      SETTINGS[:foreman_opennebula] = { assets: { precompile: assets_to_precompile } }
    end
  end
end
