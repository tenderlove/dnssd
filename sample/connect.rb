require 'dnssd'

port = Socket.getservbyname 'blackjack'
server = TCPServer.new nil, port
Thread.start do server.accept end

DNSSD.announce server, 'blackjack'

socket = nil

DNSSD.browse! '_blackjack._tcp' do |reply|
  socket = reply.connect
  break
end

p socket.peeraddr

