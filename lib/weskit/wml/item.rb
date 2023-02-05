module Weskit::WML
  class Item
    include Comparable, Mixins::Validator

    attr_reader :name

    def <=> other
      case other
        when self.class then "#{name}" <=> "#{other.name}"
        when Item then "#{self.class}" <=> "#{other.class}"
        else nil
      end
    end

    def formatter= item
      raise_unless Formatter, item
      @formatter = item
    end

    def initialize name, defaults = {}
      self.name = name
      merge defaults
    end

    def merge options = {}
      raise_unless Hash, options

      options.each do |option, value|
        raise_if_missing self, option
        send "#{option}=", value
      end

      self
    end

    def name= name
      raise_if_invalid name
      @name = Item.identifier name
    end

    def to_s
      formatter.format_detached self
    end

    alias_method :to_str, :to_s

    class << self
      def identifier name
        "#{name}".to_sym
      end

      private

      def attachable_to name
        class_eval <<-code
          attr_reader :#{name}

          def #{name}= item
            raise_unless Element, item
            @#{name} = item
          end

          def #{name}?
            !!#{name}
          end

          alias_method :attach_to, :#{name}=

          def detach
            if #{name}?
              @#{name}.delete self
              @#{name} = nil
            end
            self
          end

          def distance
            #{name} ? #{name}.distance + 1 : 0
          end

          def formatter
            current_formatter = @formatter || Formatter.default
            #{name} ? #{name}.formatter : current_formatter
          end
        code
      end
    end
  end
end