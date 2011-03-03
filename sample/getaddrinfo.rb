require 'dnssd'

Thread.abort_on_exception = true

abort "#{$0} \"http service name\"" if ARGV.empty?

resolver = DNSSD.resolve ARGV.shift, '_http._tcp', 'local' do |reply|
  addresses = []

  service = DNSSD::Service.new

  service.getaddrinfo reply.target do |addrinfo|
    addresses << addrinfo.address
    break unless addrinfo.flags.more_coming?
  end

  puts "Addresses for #{reply.target}:\n#{addresses.join "\n"}"
  exit
end

trap 'INT' do resolver.stop; exit end
trap 'TERM' do resolver.stop; exit end

sleep

