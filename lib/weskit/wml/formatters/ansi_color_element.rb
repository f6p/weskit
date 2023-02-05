module Weskit::WML::Formatters
  class AnsiColorElement < Element
    include  ::Weskit::WML::Formatters::AnsiColor

    private

    def defaults
      hash = super

      hash[:amend_char]   = control hash[:amend_char]
      hash[:closing_char] = control hash[:closing_char]
      hash[:closing]      = control hash[:closing]
      hash[:opening]      = control hash[:opening]

      hash
    end

    def name element
      element super
    end
  end
end