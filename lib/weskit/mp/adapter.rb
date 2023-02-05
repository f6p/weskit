require 'term/ansicolor'

module Weskit::MP
  class Adapter
    attr_accessor :buffer, :parser, :socket

    def initialize connection, debug = false
      @connection = connection
      @debug      = debug
      @parser     = :simple
    end

    def message container, hash
      msg = {container => hash}
      write msg
    end

    def read
      size = @connection.socket.read(4).unpack('N').first
      data = StringIO.new @connection.socket.read(size)

      read_nodes data
    end

    def write object
      case object
        when Hash   then write_hash object
        when String then write_string object
      end
    end

    private

    def compress data
      gzw = Zlib::GzipWriter.new StringIO.new
      gzw.write "#{data}"
      gzw.close
    end

    def debug node
      node = node.dup
      node.formatter = ::Weskit::WML::Formatter.color

      node
    end

    def debug_header type
      header = case type
        when :read  then Term::ANSIColor.red "server:"
        when :write then Term::ANSIColor.magenta "client:"
      end

      [$/, header]
    end

    def read_nodes data
      @buffer = nil

      puts debug_header(:read) if @debug
      @buffer = ::Weskit::WML::Parser.string Zlib::GzipReader.new(data).read, @parser
      puts debug(@buffer) if @debug

      @buffer
    end

    def write_hash hsh
      write_wml ::Weskit::WML::Builder.convert(hsh)
    end

    def write_string str
      zstr = compress str
      size = [zstr.size].pack 'N'
      @connection.socket.send "#{size}#{zstr.string}", 0
    end

    def write_wml node
      puts debug_header(:write) if @debug
      write_string "#{node}"
      puts debug(node) if @debug
    end
  end
end
