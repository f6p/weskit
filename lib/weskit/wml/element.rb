module Weskit::WML
  class Element < Item
    include Mixins::Container, Mixins::Searchable, Mixins::Validator

    attachable_to :parent
    
    attr_reader :contents

    def << item
      (append? item) ? append(item) : add(item)
      item.attach_to self
      self
    end

    def amendment= bool
      @amendment = bool ? true : false
    end

    def amendment?
      @amendment
    end

    def find name, nested = false
      find_elements name, nested
    end

    alias_method :method_missing, :find

    def initialize name, defaults = {}
      @amendment, @contents = false, []
      super
    end
  end
end