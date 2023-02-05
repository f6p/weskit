require 'term/ansicolor'

module Weskit::WML::Formatters
  module AnsiColor
    module_function

    private

    def ac
      Term::ANSIColor
    end

    def reset
      ac.reset
    end

    def attribute text
      "#{attribute_color}#{text}#{reset}"
    end

    def attribute_color
      ac.yellow
    end

    def val text
      "#{value_color}#{text}#{reset}"
    end

    def val_color
      ac.intense_cyan
    end

    def control text
      "#{control_color}#{text}#{reset}"
    end

    def control_color
      ac.intense_blue
    end

    def element text
      "#{element_color}#{text}#{reset}"
    end

    def element_color
      ac.intense_green
    end
  end
end