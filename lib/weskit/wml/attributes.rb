module Weskit::WML
  class Attributes < Items
    undef_method :attrs, :attributes
    undef_method :elems, :elements

    def [] name
      name = ::Weskit::WML::Item.identifier name
      attribute(name).value
    end

    def << item
      append_attribute item
      self
    end
  end
end