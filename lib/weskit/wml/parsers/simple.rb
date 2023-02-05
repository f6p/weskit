module Weskit::WML::Parsers
  class Simple
    attr_accessor :result

    def initialize data
      @data = data.to_s
    end

    def parse
      root    = Weskit::WML::Root.new
      stack   = []
      current = root

      lines.each do |line|
        line.strip!

        if attribute? line
          current << Weskit::WML::Attribute.new(*current_attribute)

        elsif amending_tag? line
          stack.push current
          current = Weskit::WML::Element.new(current_tag, :amendment => true)

        elsif closing_tag? line
          if current.name != current_tag
            debugger
            raise Weskit::WML::Errors::ParseError
          end
          stack.last << current
          current = stack.pop

        elsif opening_tag? line
          stack.push current
          current = Weskit::WML::Element.new(current_tag)

        end
      end

      @result = root.empty? ? nil : root
    end

    private

    def lines
      @data.lines.collect &:strip
    end

    def attribute? line
      !!(@current_match = line.match attribute)
    end

    def tag? line, prefix
      !!(@current_match = line.match tag(prefix))
    end

    def amending_tag? line
      tag? line, '\+'
    end

    def closing_tag? line
      tag? line, '\/'
    end

    def opening_tag? line
      tag? line, ''
    end

    def data_rule
      '(.+)'
    end

    def id_rule
      '([a-z][0-9a-z_]*)'
    end

    def attribute
      /^#{id_rule}\s*=\s*_?\s*#{data_rule}$/i
    end

    def tag prefix
      /^\[#{prefix}#{id_rule}\]$/i
    end

    def current_attribute
      tmp = @current_match[1..2].collect &:strip

      name  = attribute_name tmp.first
      value = attribute_value tmp.last

      [name, value]
    end

    def attribute_name string
      string.to_sym
    end

    def attribute_value string
      case string
        when /^"(.*)"$/ then $1.strip
        when /^"(.*)$/  then $1.strip + '...'
        else string
      end.gsub '""', '"'
    end

    def current_tag
      @current_match[1].to_sym
    end
  end
end
