module Weskit::WML::Formatters
  class Attribute < ItemFormatter
    def format attribute, indent = 0
      content = "#{name attribute}#@assignment#{value attribute}"
      @formatter.indent content, indent
    end

    private

    def defaults
      {
        :assignment => '=',
        :code_start => '<<',
        :code_end   => '>>',
        :quote      => '"',
        :underscore => '_'
      }
    end

    def escape value
      value.gsub @quote, escape_sequence
    end

    def escape_sequence
      @quote * 2
    end

    def text attribute
      "#{attribute.value}"
    end

    def name attribute
      "#{attribute.name}"
    end

    def code_value attribute
      "#@code_start#{text attribute}#@code_end"
    end

    def raw_value attribute
      text attribute
    end

    def text_value attribute
      string = escape text attribute
      string = "#@quote#{string}#@quote"

      return "#@underscore#{string}" if attribute.translatable?
      string
    end

    def value attribute
      method = if attribute.code?
        :code_value
      elsif attribute.text?
        :text_value
      else
        :raw_value
      end

      send method, attribute
    end
  end
end