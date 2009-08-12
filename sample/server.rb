require 'dnssd'

port = Socket.getservbyname 'blackjack'
blackjack = TCPServer.new nil, port

DNSSD.announce blackjack, 'blackjack server'

trap 'INT'  do exit; end
trap 'TERM' do exit; end

loop do
  socket = blackjack.accept
  peeraddr = socket.peeraddr
  puts "Connection from %s:%d" % socket.peeraddr.values_at(2, 1)
end

