module Imouto
  class RatelimitedQueue
    attr_reader :messages_per_interval, :interval_in_seconds

    def initialize(messages_per_interval, interval_in_seconds)
      @messages_per_interval = messages_per_interval
      @interval_in_seconds = interval_in_seconds
      @messages_this_interval = 0
      @current_interval = Time.now
      @items = []
    end

    def enqueue(item)
      @items << item
    end

    def dequeue
      loop {
        if @items.empty?
          sleep 1
          next
        end
        interval = Time.now
        if interval > @current_interval + @interval_in_seconds
          @current_interval = interval
          @messages_this_interval = 0
        end
        if @messages_this_interval < @messages_per_interval
          @messages_this_interval += 1
          yield @items.shift
        end
      }
    end
  end
end
