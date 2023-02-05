module Weskit::WML::Formatters
  class AnsiColorAttribute < Attribute
    include ::Weskit::WML::Formatters::AnsiColor

    private

    def defaults
      hash = super

      hash[:assignment] = control hash[:assignment]
      hash[:code_start] = control hash[:code_start]
      hash[:code_end]   = control hash[:code_end]
      hash[:quote]      = control hash[:quote]
      hash[:underscore] = control hash[:underscore]

      hash
    end

    def escape_sequence
      reset + "#{@quote * 2}" + val_color
    end

    def text attribute
      val_color + "#{attribute.value}" + reset
    end

    def name attribute
      attribute super
    end
  end
end