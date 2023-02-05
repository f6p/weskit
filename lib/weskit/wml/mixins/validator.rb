module Weskit::WML::Mixins
  module Validator
    module_function

    def raise_unless type, item
      unless item.is_a? type
        raise ::Weskit::WML::Errors::InvalidItem, "Invalid #{type}"
      end
    end

    def raise_if_invalid identifier
      unless "#{identifier}".match identifier_pattern
        raise ::Weskit::WML::Errors::InvalidIdentifier, "Invalid identifier: #{identifier}"
      end
    end

    def raise_if_missing object, method
      unless object.respond_to? "#{method}="
        raise ::Weskit::WML::Errors::InvalidOption, "Object doesn't have: #{method}"
      end
    end

    private

    def identifier_pattern
      /^[a-z][a-z_0-9]*$/i
    end
  end
end
