require 'dnssd'

Thread.abort_on_exception = true

trap 'INT'  do exit end
trap 'TERM' do exit end

service = nil

DNSSD.browse! '_blackjack._tcp', 'local.' do |reply|
  service = reply
  break
end

puts "found service #{service.name}"

socket = service.connect

puts "Connected to %s:%d" % socket.peeraddr.values_at(2, 1)

