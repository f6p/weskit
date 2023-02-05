require 'open-uri'
require 'stringio'
require 'zlib'
    
module Weskit::WML
  class Parser
    private_class_method :new

    class << self
      def string str, bck = :kpeg
        parse str, bck
      end

      def uri uri, bck = :kpeg
        begin
          str = open(uri).read
        rescue
          raise Errors::ReadError, "Couldn't open URI"
        ensure
          str = Zlib::GzipReader.new(StringIO.new str).read rescue str
        end

        parse str, bck
      end

      private

      def backends
        {
          :kpeg   => Parsers::KPEG,
          :simple => Parsers::Simple
        }
      end

      def parse data, backend
        data   = Preprocessor.new(data).remove_directives
        parser = backends[backend].new "#{data}\n"

        parser.parse
        parser.result
      end
    end
  end
end
