module Weskit::WML::Mixins
  module Grammar
    module_function

    def raise_on_mismatch opening, closing
      unless opening.name == closing.name
        raise ::Weskit::WML::Errors::ParseError, 'Invalid element'
      end
    end

    def reject_non_wml elements
      elements.reduce(Array.new) do |array, element|
        array << element.item if element.respond_to? :item ; array
      end
    end
  end
end
