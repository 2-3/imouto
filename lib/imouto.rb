require_relative 'irc'
require_relative 'ratelimited_queue'

module Imouto

  # IRC-PRIVMSG, passed to matchers.
  Message = Struct.new(
    # PRIVMSG as string.
    :message,
    # Captures specified in matcher-regex
    :captures,
    # Raw MatchData
    :raw
  )

  ImoutoConfig = Struct.new(
    :loggers,
    :message_interval_size,
    :messages_per_interval
  )

  class Bot
    attr_reader :matchers, :irc, :reply_queue

    def initialize(irc, conf)
      imouto_config = ImoutoConfig.new
      conf.each { |k, v| imouto_config[k] = v; }
      @loggers = imouto_config.loggers || [->(msg) { p msg }]
      @matchers = {}
      @irc = irc
      @reply_queue = Imouto::RatelimitedQueue.new(
        imouto_config.messages_per_interval || 3,
        imouto_config.message_interval_size || 4)
    end

    # Starts the bot, spawning a read- and a write-thread
    def start
      read_thread = Thread.new { read(@irc) }
      write_thread = Thread.new { dequeue_replies }
      read_thread.join
      write_thread.join
    end

    # Read from the IRC-connection until it closes.
    def read(irc_con = @irc)
      irc_con.start.read { |msg, matchers = @matchers|
        matchers.keys.each { |regex|
          msg[:message] =~ regex && reply(msg, matchers[regex], regex.match(msg[:message]))
        }
      }
    end

    # Reply to a PRIVMSG
    def reply(msg, matcher, matches)
      log("[Executing Matcher] #{msg[:message]}")
      m = Message.new(msg[:message], matches, msg)
      begin
        reply = Thread.new { matcher.call(m) }.value
      rescue StandardError => e
        log("[Matcher Exception] #{e}")
      end
      reply_to = msg[:target].start_with?('#') ? msg[:target] : msg[:nick]
      queue_reply(reply_to, reply)
    end

    # Write replies to the IRC-connection
    def dequeue_replies(irc_con = @irc)
      @reply_queue.dequeue { |reply, irc = irc_con|
        log("[->] #{reply['target']}: #{reply['reply']}")
        irc.privmsg(reply['target'], reply['reply'])
      }
    end

    # Enqueues a reply, to be sent.
    # You can also directly send messages by using @irc.privmsg
    # this however bypasses rate limiting and might get you kicked.
    def queue_reply(target, reply)
      @reply_queue.enqueue('target' => target, 'reply' => reply)
    end

    # Calls every logger with a message.
    def log(msg)
      @loggers.each { |l| l.call(msg) }
    end

    # Registers a matcher to respond to PRIVMSGs that match a certain regex.
    def register_matcher(regex, matcher)
      return false unless matcher.respond_to? 'call'
      @matchers[regex] = matcher
      log("[Registered Matcher] #{regex}")
    end

    # Consumes a regex, and removes the matcher that was registered with it.
    def unregister_matcher(regex)
      @matchers.delete(regex)
      log("[Removed Matcher] #{regex}")
    end
  end
end
