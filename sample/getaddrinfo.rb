require 'dnssd'

abort "#{$0} \"http service name\"" if ARGV.empty?

resolver = DNSSD.resolve ARGV.shift, '_http._tcp', 'local' do |reply|
  addresses = []

  service = DNSSD::Service.new
  begin
    service.getaddrinfo reply.target do |addrinfo|
      addresses << addrinfo.address.last
      break unless addrinfo.flags.more_coming?
    end
  ensure
    service.stop
  end

  puts "Addresses for #{reply.target}:\n#{addresses.join "\n"}"
  exit
end

trap 'INT' do resolver.stop; exit end
trap 'TERM' do resolver.stop; exit end

sleep

