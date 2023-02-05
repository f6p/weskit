module Weskit::WML::Formatters
  class Element < ItemFormatter
    def format element, indent = 0
      contents = []

      contents.push @formatter.indent(opening_tag(element), indent)
      contents += element.contents.collect {|i| @formatter.format i, indent + 1}
      contents.push @formatter.indent(closing_tag(element), indent)

      contents.join @formatter.separator
    end

    private

    def defaults
      {
        :amend_char   => '+',
        :closing_char => '/',
        :closing      => ']',
        :opening      => '['
      }
    end

    def closing_tag element
      tag "#@closing_char#{name element}"
    end

    def name element
      "#{element.name}"
    end

    def opening_prefix element
      element.amendment? ? "#@amend_char" : ''
    end

    def opening_tag element
      tag "#{opening_prefix element}#{name element}"
    end

    def tag content
      "#@opening#{content}#@closing"
    end
  end
end