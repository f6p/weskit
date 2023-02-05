module Weskit::WML
  class Formatter
    private_class_method :new

    attr_reader :separator

    def format item, indentation = 0
      case item
        when Attribute then @attr_formatter.format item, indentation
        when Element   then @elem_formatter.format item, indentation
      end
    end

    def format_detached item, formatter = nil
      formatter ||= item.formatter
      duplicate   = item.dup.detach

      duplicate.formatter = formatter
      format item
    end

    def indent content, width = 0
      @indent * width + "#{content}"
    end

    def initialize options = {}
      options = options_default.merge options

      @attr_formatter = options[:attr_formatter].new self
      @elem_formatter = options[:elem_formatter].new self

      @indent    = options[:indent]
      @separator = options[:separator]

      self
    end

    private

    def options_default
      {
        :indent    => '  ',
        :separator => $/
      }
    end

    class << self
      def color
        @color ||= new options_color
      end

      def default
        @default or plain
      end

      def default= item
        Mixins::Validator.raise_unless Formatter, item
        @default = item
      end

      def plain
        @plain ||= new options_plain
      end

      private

      def options_color
        {
          :attr_formatter => Formatters::AnsiColorAttribute,
          :elem_formatter => Formatters::AnsiColorElement
        }
      end

      def options_plain
        {
          :attr_formatter => Formatters::Attribute,
          :elem_formatter => Formatters::Element
        }
      end
    end
  end
end