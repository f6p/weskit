module Weskit::WML
  class Builder
    private_class_method :new

    def attribute name, value, defaults = nil
      a = Attribute.new name, value, defaults || {}
      @built << a ; a
    end

    def create &contents
      instance_eval &contents ; @built
    end

    def element name, defaults = nil
      e = Element.new name, defaults || {}
      @built << e ; e
    end

    def id value
      attribute :id, value
    end

    def initialize
      @built = []
    end

    def method_missing *params
      p = params
      unless block_given?
        raise_invalid_count if p.size < 2
        attribute p[0], p[1], p[2]
      else
        raise_invalid_count if p.size < 1
        element(p[0], p[1]).build &Proc.new
      end
    end

    private

    def raise_invalid_count
      raise Errors::InvalidParameters, "Invalid number of parameters"
    end

    class << self
      def build &contents
        new.create &contents
      end

      def convert hash
        root = Root.new

        hash.each do |k, v|
          if v.is_a? Hash
            e = Element.new k
            e.push *Builder.convert(v)
            root << e
          else
            root << Attribute.new(k, v)
          end
        end

        root
      end
    end
  end
end