module ForemanOpennebula
  module FormHelperExtensions
    extend ActiveSupport::Concern

    def megabyte_size_f(f, attr, options = {})
      react_form_input('memorySize', f, attr, options)
    end
  end
end
