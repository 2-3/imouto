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

  class Enum
    attr_reader :options, :selected

    def initialize(options, selected)
      raise ArgumentError, "Expected argument options to respond to method 'at'" unless options.respond_to? 'at'
      @options = options
      @selected = options.first
      set selected
    end

    def set(value)
      return @selected unless @options.include? value
      @selected = value
    end
  end

  class Irc
    include IrcCommands

    attr_reader :connection, :user, :connection_state


    def initialize(connection, user)
      @connection = Connection.new
      connection.each { |k, v| @connection[k] = v; }
      @user = User.new
      user.each { |k, v| @user[k] = v; }
      @connection_state = Enum.new([:not_connected, :connecting, :connected, :failed], :not_connected)
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
        @connection_state.set(:failed)
        puts 'Timeout! Aborting.'
        return false
      rescue SocketError => e
        @connection_state.set(:failed)
        puts "Network error: #{e}"
        return false
      rescue => e
        @connection_state.set(:failed)
        puts "General exception: #{e}"
        return false
      end
      @connection_state.set(:connecting)
      self
    end

    # Yields PRIVMSGs and handles PINGs as well as setup operations
    def read
      until @socket.eof?
        msg = @socket.gets
        if msg.start_with? 'PING'
          raw "PONG #{msg[6..-1]}"
          next
        end
        if  msg.include? 'PRIVMSG'
          m = msg.chomp.match(/:(?<nick>.*)!(?<mask>.*) PRIVMSG (?<target>.*) :(?<message>.*)$/)
          yield m
        end
        if (@connection_state.selected == :connecting) && (msg =~ /:(.*) 376 #{@user.nick} :(.*)$/)
          setup
          @connection_state.set(:connected)
          next
        end
      end
    end

  end
end
