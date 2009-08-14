require 'dnssd'

Thread.abort_on_exception = true

port = Socket.getservbyname 'blackjack'
blackjack = TCPServer.new nil, port

DNSSD.announce blackjack, 'blackjack server'

trap 'INT'  do exit; end
trap 'TERM' do exit; end

puts "Running 'blackjack server' on port %d" % blackjack.addr[1]
puts 'Now run sample/socket.rb'

loop do
  socket = blackjack.accept
  peeraddr = socket.peeraddr
  puts "Connection from %s:%d" % socket.peeraddr.values_at(2, 1)
end

