require 'forwardable'

module Weskit::MP
  class Worker
    extend Forwardable

    attr_reader :debug, :nickname
    def_delegators :@connection, :message, :read, :write

    def connect_and &operate
      @connection.open do
        instance_eval &operate
      end
    end

    def initialize nickname
      @connection = Connection.new self
      @nickname   = nickname
    end

    def login
      message 'login', {:selective_ping => 1, :username => @nickname}
      read ; verify_response :mustlogin
      read ; verify_response :join_lobby
    end

    def verify_response element
      element = @connection.buffer.find(element).first

      unless element
        raise Errors::ResponseError, "Server send node other than '#{element}'"
      end
    end
  end
end