require 'weskit/version'

module Weskit
  module WML
    def self.require_all files, folder = nil
      folder = (folder.to_s || '') + '/'
      files.collect {|file| require "weskit/wml/#{folder}#{file}"}
    end
  end
end

w = Weskit::WML
w.require_all %w{validator grammar searchable container}, :mixins
w.require_all %w{object}, :extensions
w.require_all %w{error invalid_identifier invalid_item invalid_option invalid_parameters parse_error read_error}, :errors
w.require_all %w(kpeg simple), :parsers
w.require_all %w{item_formatter attribute element ansi_color ansi_color_attribute ansi_color_element}, :formatters
w.require_all %w{item items attribute attributes builder element elements formatter preprocessor parser root}
