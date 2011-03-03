require 'dnssd'

Thread.abort_on_exception = true
trap 'INT' do exit end
trap 'TERM' do exit end

class ChatNameResolver
  def self.resolve_add(reply)
    Thread.new reply do |reply|
      DNSSD.resolve reply.name, reply.type, reply.domain do |resolve_reply|
        puts "Adding: #{resolve_reply.inspect}"
        break
      end
    end
  end
  def self.resolve_remove(reply)
    Thread.new reply do |reply|
      DNSSD.resolve reply.name, reply.type, reply.domain do |resolve_reply|
        puts "Removing: #{resolve_reply.inspect}"
        break
      end
    end
  end
end

DNSSD.browse '_presence._tcp' do |reply|
  if reply.flags.add? then
    ChatNameResolver.resolve_add reply
  else
    ChatNameResolver.resolve_remove reply
  end
end

sleep

