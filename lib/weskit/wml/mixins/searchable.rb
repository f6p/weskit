module Weskit::WML::Mixins
  module Searchable
    def find_recursively &criteria
      ::Weskit::WML::Elements.new *elements_recursively.select(&criteria)
    end

    def elements_recursively
      element_contents + element_contents.reduce(Array.new) do |r, i|
        r + i.elements_recursively
      end
    end

    private

    def append item
      find_elements(item.name, false).last.push(*item.contents) rescue nil
    end

    def append? item
      item.is_a? ::Weskit::WML::Element and item.amendment?
    end

    def base nested
      nested ? nested_contents : contents
    end

    def element_contents
      contents.select {|i| i.is_a? ::Weskit::WML::Element}
    end

    def find_elements name, nested = false
      name  = ::Weskit::WML::Item.identifier name
      found = base(nested).select {|i| i.is_a? ::Weskit::WML::Element and i.name == name}
      ::Weskit::WML::Elements.new *found
    end

    def nested_contents
      contents.reduce(Array.new) do |r, i|
        r + i.contents
      end
    end
  end
end