## imouto
A really basic &amp; lightweight IRC-client-lib. Mix with a few λs for instant bot.


###Functionality
Imouto is intended to be a base for IRC-bots. It doesn't do anything breathtaking, but also won't get in your way.
Following that spirit, it isn't a complete implementation of the RFCs. It's easy to add commands though.

You can use only the IRC-client functionality and do whatever you like with the PRIVMSGs,
or use the provided IRC-bot skeleton which provides:
- Matchers: Execute λ for a given RegEx and reply with the result.
- Rate Limiting: Most IRC-networks kick you if you send a lot of messages in too short a time, this avoids that. 
- Logging: Very basic interface to log stuff.

##Installation
Imouto is a ruby gem. If you don't know how to install ruby gems, you should probably google it.
Because it's a cool thing and you should know.

###Examples
Using only the IRC-client functionality:

	require "imouto"
	
	
	config_connection = {
		'server' => 'futurelab.irc',
		'port' => 6667,
		'channels' => ['#future_lab'],
		'connect_timeout' => 10,
		'read_timeout' => 240,
	}
	config_user = {
		'nick' => 'parttimer',
		'username' => 'bicycle_master',
		'realname' => 'John Titor',
		'password' => 'elpsycongroo'
	}
	
	con = Imouto::Irc.new(config_connection, config_user)
	con.start.read {|m|
		reply_to = m[:target].start_with?('#') ? m[:target] : m[:nick]
		con.privmsg(reply_to, m[:message])
	}

Using Imouto with the included bot:

	require "imouto"
	
	
	config_connection = {
		'server' => 'futurelab.irc',
		'port' => 6667,
		'channels' => ['#future_lab'],
		'connect_timeout' => 10,
		'read_timeout' => 240,
	}
	config_user = {
		'nick' => 'parttimer',
		'username' => 'bicycle_master',
		'realname' => 'John Titor',
		'password' => elpsycongroo
	}
	config_imouto = {
		'message_interval_size' => 4,
		'messages_per_interval' => 3,
		'loggers' => [lambda {|msg| p msg}, SomethingCallable]	
	}
	
	con = Imouto::Irc.new(config_connection, config_user)
	bot = Imouto::Bot.new(con, config_imouto)
	bot.register_matcher(/foo/, lambda {|msg| 'foo'})
	bot.start()

