module Weskit::WML
  class Elements < Items
    include Mixins::Container, Mixins::Searchable

    undef_method :attrs, :attributes
    undef_method :elems, :elements

    def [] key
      case key
        when Integer then contents[key]
        else contents[0][key] rescue nil
      end
    end

    def << item
      raise_unless Element, item
      item.amendment? ? append(item) : add(item)
      self
    end

    def find name, nested = true
      find_elements name, nested
    end

    alias_method :method_missing, :find
  end
end