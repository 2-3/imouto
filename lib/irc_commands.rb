module IrcCommands
  # Overwrite raw() to send to your socket wherever you include this
  def raw(string)
    puts string
  end

  def mode(nick, state, mode)
    return false unless %w(a i w r o O s).include? mode
    raw "MODE #{nick} #{state}#{mode}"
  end

  def quit(msg = '')
    raw "QUIT :#{msg}"
  end

  def join(channels)
    channels.respond_to?('join') && channels = channels.join(',')
    raw "JOIN #{channels}"
  end

  def part(channels, msg = '')
    channels.respond_to?('join') && channels = channels.join(',')
    raw "PART #{channels} :#{msg}"
  end

  def channel_mode(channel, state, mode, modeparams = '')
    return false unless %w(O o v a i m n q p s r t k l b e I).include? mode
    raw "MODE #{channel} #{state} #{mode} #{modeparams}"
  end

  def topic(channel, topic)
    raw "TOPIC #{channel} :#{topic}"
  end

  def invite(nick, channel)
    raw "INVITE #{nick} #{channel}"
  end

  def kick(channel, user, reason = '')
    raw "KICK #{channel} #{user} :#{reason}"
  end

  def privmsg(target, msg)
    raw "PRIVMSG #{target} :#{msg}"
  end

  def notice(target, msg)
    raw "NOTICE #{target} :#{msg}"
  end
end
