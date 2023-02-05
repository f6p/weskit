require 'forwardable'
require 'socket'
require 'stringio'
require 'zlib'

module Weskit::MP
  class Connection
    extend Forwardable

    attr_reader :adapter, :options, :socket
    def_delegators :adapter, :buffer, :message, :read, :write

    def close
      @socket.close
    end

    def defaults
      {
        :debug   => false,
        :host    => 'server.wesnoth.org',
        :port    => 15000,
        :version => '1.10.0'
      }
    end

    def initialize worker, options = {}
      @options = defaults.merge options

      @adapter = Adapter.new self, @options[:debug]
      @worker  = worker
    end

    def open
      @socket = socket_for destination_socket
      @worker.login
      
      if block_given?
        result = yield
        close ; result
      end
    end

    private

    def destination_socket
      @socket  = socket_for @options
      redirect = read.redirect

      @socket.close
      redirect
    end

    def socket_for hash
      @socket = TCPSocket.new hash[:host], hash[:port]

      socket_handshake
      socket_init

      @socket
    end

    def socket_handshake
      @socket.send "\x00" * 4, 0
      @socket.read 4
    end

    def socket_init
      read

      @worker.verify_response :version
      message 'version', {:version => @options[:version]}
    end
  end
end