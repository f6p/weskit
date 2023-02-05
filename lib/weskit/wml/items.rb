module Weskit::WML
  class Items
    include Enumerable, Mixins::Container, Mixins::Validator

    attr_reader :contents

    def formatter
      @formatter or Formatter.default
    end

    def formatter= item
      raise_unless Formatter, item
      @formatter = item
    end

    def initialize *items
      @contents = []
      push *items
    end

    def to_s
      @contents.collect do |item|
        formatter.format_detached item, formatter
      end.join formatter.separator
    end

    alias_method :to_str, :to_s
  end
end