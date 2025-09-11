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

    initializer 'foreman_opennebula.register_plugin', :before => :finisher_hook do |app|
      app.reloader.to_prepare do
        Foreman::Plugin.register :foreman_opennebula do
          requires_foreman '>= 3.14.0'
          compute_resource ForemanOpennebula::Opennebula
          register_global_js_file 'global'

          parameter_filter Subnet, :opennebula_vnet
        end
      end
    end

    initializer 'foreman_opennebula.load_app_instance_data' do |app|
      ForemanOpennebula::Engine.paths['db/migrate'].existent.each do |path|
        app.config.paths['db/migrate'] << path
      end
    end

    config.to_prepare do
      require 'fog/opennebula/models/compute/server'
      require 'fog/opennebula/models/compute/flavor'
      require 'fog/opennebula/models/compute/interface'
      require File.expand_path('../../app/models/concerns/fog_extensions/open_nebula/server', __dir__)
      require File.expand_path('../../app/models/concerns/fog_extensions/open_nebula/flavor', __dir__)
      require File.expand_path('../../app/models/concerns/fog_extensions/open_nebula/interface', __dir__)
      require File.expand_path('../../app/helpers/concerns/foreman_opennebula/form_helper_extensions', __dir__)

      ::Fog::Compute::OpenNebula::Server.include(FogExtensions::OpenNebula::Server)
      ::Fog::Compute::OpenNebula::Flavor.include(FogExtensions::OpenNebula::Flavor)
      ::Fog::Compute::OpenNebula::Interface.include(FogExtensions::OpenNebula::Interface)
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
