require 'dnssd'

DNSSD.resolve 'blackjack', '_blackjack._tcp', 'local.' do |reply|
  puts "#{reply.name} at #{reply.port}"
end

port = Socket.getservbyname 'blackjack'
blackjack = TCPServer.new 'localhost', port

DNSSD.announce blackjack, 'blackjack', 'blackjack'

trap 'INT'  do exit; end
trap 'TERM' do exit; end

sleep
