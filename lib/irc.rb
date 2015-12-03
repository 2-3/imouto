require 'timeout'
require 'net/protocol'
require_relative 'irc_commands'

module Imouto
  Connection = Struct.new(
    :server,
    :port,
    :channels,
    :connect_timeout,
    :read_timeout
  )

  User = Struct.new(
    :nick,
    :username,
    :realname,
    :password
  )

  class Irc
    include IrcCommands

    attr_reader :connection
    attr_reader :user

    def initialize(connection, user)
      @connection = Connection.new
      connection.each { |k, v| @connection[k] = v; }
      @user = User.new
      user.each { |k, v| @user[k] = v; }
      self
    end

    # Stuff to do when the connection is successfully established
    def setup
      join @connection.channels
      self
    end

    # see irc_commands.rb
    def raw(msg)
      @socket.puts msg
    end

    # Starts an IRC-connection. Chainable,-
    # you probably want to do irc.start.read {|msg| ...}
    def start
      begin
        Timeout.timeout(@connection.connect_timeout) {
          @socket = TCPSocket.new(@connection.server, @connection.port)
          raw "PASS #{@user.password}"
          raw "NICK #{@user.nick}"
          raw "USER #{@user.username} 0 * :#{@user.realname}"
        }
      rescue Timeout::Error
        puts 'Timeout! Aborting.'
        return false
      rescue SocketError => e
        puts "Network error: #{e}"
        return false
      rescue => e
        puts "General exception: #{e}"
        return false
      end
      self
    end

    # Yields PRIVMSGs and handles PINGs as well as setup operations
    def read
      setup_complete = false
      until @socket.eof?
        msg = @socket.gets
        if msg.start_with? 'PING'
          raw "PONG #{msg[6..-1]}"
          next
        end
        if (!setup_complete) && (msg =~ /:(.*) 376 #{@user.nick} :(.*)$/)
          setup
          setup_complete = true
          next
        end
        if  msg.include? 'PRIVMSG'
          m = msg.chomp.match(/:(?<nick>.*)!(?<mask>.*) PRIVMSG (?<target>.*) :(?<message>.*)$/)
          yield m
        end
      end
    end
  end
end
