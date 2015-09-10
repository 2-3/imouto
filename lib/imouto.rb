require_relative "irc"
require_relative "ratelimited_queue"


module Imouto

  Message = Struct.new(
    :message,
    :captures,
    :raw
  )
  
  class Bot

    attr_reader :matchers
    attr_reader :irc
    attr_reader :reply_queue
    
    public
    
    def initialize(irc)
      @loggers = [lambda {|msg| p msg}]
      @matchers = Hash.new
      @irc = irc
      @reply_queue = Imouto::RatelimitedQueue.new(3, 4)
    end
    
    def start()
      read_thread = Thread.new do @irc.start.read {|privmsg, matchers = @matchers|
        matchers.keys.each{|regex|
          message = privmsg[:message]
          if message =~ regex then
            log("[Executing Matcher] #{message}")
            m = Message.new(
              message,
              regex.match(message),
              privmsg
            )
            reply_to = privmsg[:target].start_with?('#') ? privmsg[:target] : privmsg[:nick]
            begin
              reply = Thread.new{matchers[regex].call(m)}.value
            rescue StandardError => e
              log("[Matcher Exception] #{e}")
              next
            end
            queue_reply(reply_to, reply)
            log("[-> Queue] #{reply_to}: #{reply}")
          end
        }
      }
      end
      write_thread = Thread.new do @reply_queue.dequeue{|r, irc = @irc|
        log("[<- Queue] #{r['target']}: #{r['reply']}")
        @irc.privmsg(r['target'], r['reply'])
      }
      end
      read_thread.join
      write_thread.join
    end
    
    def log (msg)
      @loggers.each {|l| l.call(msg)}
    end

    def queue_reply(target, reply)
      @reply_queue.enqueue({'target' => target, 'reply' => reply})
    end
    
    def register_matcher(regex, matcher)
      if matcher.respond_to? 'call'
        @matchers[regex] = matcher
        log("[Registered Matcher] #{regex}")
      end
    end
    
    def unregister_matcher(regex)
      @matchers.delete(regex)
      log("[Removed Matcher] #{regex}")
    end
  end
end