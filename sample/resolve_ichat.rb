require 'dnssd'
require 'pp'

Thread.abort_on_exception = true

class ChatNameResolver
  def self.resolve_add(reply)
    Thread.new reply do |reply|
      DNSSD.resolve reply.name, reply.type, reply.domain do |resolve_reply|
        puts "Adding: #{resolve_reply.inspect}"
        pp resolve_reply.text_record
        resolve_reply.service.stop
      end
    end
  end
  def self.resolve_remove(reply)
    Thread.new reply do |reply|
      DNSSD.resolve reply.name, reply.type, reply.domain do |resolve_reply|
        puts "Removing: #{resolve_reply.inspect}"
        resolve_reply.service.stop
      end
    end
  end
end

browser = DNSSD.browse '_presence._tcp' do |reply|
  if reply.flags.add? then
    ChatNameResolver.resolve_add reply
  else
    ChatNameResolver.resolve_remove reply
  end
end

trap 'INT' do browser.stop; exit end
trap 'TERM' do browser.stop; exit end

sleep

