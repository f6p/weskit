require 'forwardable'

module Weskit::WML::Mixins
  module Container
    extend Forwardable
    include ::Weskit::WML::Mixins::Validator

    def_delegators :contents, :each, :empty?, :first, :last, :size, :to_a, :to_ary

    def [] key
      case key
        when Integer then elements[key]
        else attributes[key] rescue nil
      end
    end

    def << item
      raise_unless ::Weskit::WML::Item, item
      add item
      self
    end

    def attributes
      ::Weskit::WML::Attributes.new *(select_type_of ::Weskit::WML::Attribute)
    end

    alias_method :attrs, :attributes

    def build &contents
      push *(::Weskit::WML::Builder.build &contents)
    end

    def delete item
      contents.delete_if {|i| i.equal? item}
    end

    def elements
      ::Weskit::WML::Elements.new *(select_type_of ::Weskit::WML::Element)
    end

    alias_method :elems, :elements

    def exists? item
      contents.any? {|i| i.equal? item}
    end

    def push *items
      items.each {|i| self << i}
      self
    end

    private

    def add item
      return nil if exists? item

      case item
        when ::Weskit::WML::Attribute then append_attribute item
        else contents << item
      end

      item
    end

    def append item
      raise_unless ::Weskit::WML::Element, item
      find(item.name, false).last.push(*item.contents) rescue nil
    end

    def append_attribute item
      raise_unless ::Weskit::WML::Attribute, item
      index = attribute_index item
      index ? contents[index] = item : contents << item
    end

    def attribute name
      name = ::Weskit::WML::Item.identifier name
      contents.detect do |item|
        item.is_a? ::Weskit::WML::Attribute and item.name == name
      end
    end

    def attribute_index item
      contents.find_index {|i| i == item}
    end

    def attribute_value name
      found = attribute name
      found ? found.value : nil
    end

    def select_type_of constant
      contents.select {|i| i.is_a? constant}
    end
  end
end
