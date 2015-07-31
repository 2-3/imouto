module Imouto

	class RatelimitedQueue
	
		attr_reader :messages_per_second
		
		def initialize(messages_per_second)
			@messages_per_second = messages_per_second
			@messages_this_interval = 0
			@current_interval = Time.now
			@items = Array.new
		end
		
		def enqueue(item)
			@items << item
		end
		
		def dequeue
			while true
				if @items.empty? then
					sleep 1
					next
				end
				interval = Time.now
				if interval > @current_interval + 1 then
					@current_interval = interval
					@messages_this_interval = 0
				end
				if @messages_this_interval < @messages_per_second then
					@messages_this_interval += 1
					yield @items.shift
				end
			end
		end
	end
end