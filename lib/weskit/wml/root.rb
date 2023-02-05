module Weskit::WML
  class Root < Items
    include Mixins::Searchable, Mixins::Validator

    def << item
      raise_unless Item, item
      (append? item) ? append(item) : add(item)
      self
    end

    def find name, nested = false
      find_elements name, nested
    end

    alias_method :method_missing, :find
  end
end