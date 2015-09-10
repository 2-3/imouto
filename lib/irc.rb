require "timeout"
require "net/protocol"
require_relative "irc_commands"


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
    include Irc_Commands
  
    attr_reader :connection
    attr_reader :user
    
    def initialize(connection, user)
      @connection = Connection.new(
        connection['server'],
        connection['port'],
        connection['channels'],
        connection['connect_timeout'],
        connection['read_timeout']
      )
      @user = User.new(
        user['nick'],
        user['username'],
        user['realname'],
        user['password'] ||= ''
      )
      self
    end
    
    #Stuff to do when the connection is successfully established
    def setup()
      join @connection.channels
      self
    end
    
    #see irc_commands.rb
    def raw(msg)
      @socket.puts msg
    end
    
    #Starts an IRC-connection. Chainable,- you probably want to do irc.start.read {|msg| ...}
    def start()
      begin
        Timeout::timeout(@connection.connect_timeout) do
          @socket = TCPSocket.new(@connection.server, @connection.port)
          raw "PASS #{@user.password}"
          raw "NICK #{@user.nick}"
          raw "USER #{@user.username} 0 * :#{@user.realname}"
      end
      rescue Timeout::Error
          puts "timeout"
        return false
      rescue SocketError => e
          puts "network error"
        return false
      rescue => e
          puts "general exception"
        return false
      end
      self
    end
    
    #Yields PRIVMSGs and handles PINGs as well as setup operations 
    def read
      until @socket.eof? do
        msg = @socket.gets
        if msg.start_with? 'PING'
          raw "PONG #{msg[6..-1]}"
          next
        end
        if msg.include? '376' and msg =~ /:(.*) 376 #{@user.nick} :(.*)$/
          setup
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