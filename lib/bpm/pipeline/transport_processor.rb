require 'sprockets'

module BPM
  
  class TransportProcessor < Sprockets::Processor
    
    def evaluate(context, locals)
      environment = context.environment
      project = environment.project
      pkg, module_id = project.package_and_module_from_path file
      transport_plugins = pkg.transport_plugins(project)

      # No transport, just return the existing data
      return data if transport_plugins.empty?

      if transport_plugins.size > 1
        # TODO: Maybe make custom error for this
        raise "#{pkg.name} depends on #{transport_plugins.size} packages that define transport plugins. " \
                "Select a plugin by adding a `plugin:transport` property to the package.json"
      end
      
      plugin_ctx = environment.plugin_context_for transport_plugins.first
      filepath   = file.to_s
      out = ''

      V8::C::Locker() do
        plugin_ctx["PACKAGE_INFO"] = pkg.attributes
        plugin_ctx["DATA"]         = data
        out = plugin_ctx.eval("BPM_PLUGIN.compileTransport(DATA, PACKAGE_INFO, '#{module_id}', '#{filepath}');")
      end

      out + "\n\n"
    end
    
  end

end
