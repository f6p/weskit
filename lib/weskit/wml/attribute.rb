module Weskit::WML
  class Attribute < Item
    attachable_to :element

    attr_reader :value

    def code= bool
      @code = bool ? (@translatable = false ; true) : false
    end

    def code?
      @code
    end

    def multiline?
      "#{value}".include? "\n"
    end

    def text?
      code? or multiline? or translatable?
    end

    def translatable= bool
      @translatable = bool ? (@code = false ; true) : false
    end

    def translatable?
      @translatable
    end

    def initialize name, value, defaults = {}
      @code = @translatable = false

      self.name  = name
      self.value = value

      merge defaults
    end

    def value
      real_value
    end

    def value= object
      @value = object.to_s.strip
      @value.attr = self
    end

    private

    def real_value
      case @value
        when %r{^(nil|null)$}     then nil
        when %r{^(true|yes)$}     then true
        when %r{^(false|no)$}     then false
        when %r{^[0-9]*\.[0-9]+$} then Float @value
        when %r{^[0-9]+$}         then Integer @value
        else @value
      end
    end
  end
end
