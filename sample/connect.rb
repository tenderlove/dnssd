require 'dnssd'

socket = nil

DNSSD.browse! '_blackjack._tcp' do |reply|
  puts "found service #{reply.name}"
  socket = reply.connect
  break
end

puts "Connected to %s:%d" % socket.peeraddr.values_at(2, 1)

