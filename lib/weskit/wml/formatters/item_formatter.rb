module Weskit::WML::Formatters
  class ItemFormatter
    include ::Weskit::WML::Mixins::Validator

    def initialize item
      raise_unless  ::Weskit::WML::Formatter, item
      set_instance_variables
      @formatter = item
    end

    private

    def set_instance_variables
      defaults.each {|var, value| instance_variable_set "@#{var}", value}
    end
  end
end