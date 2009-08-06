require 'dnssd'

abort "#{$0} \"http service name\"" if ARGV.empty?

resolver = DNSSD.resolve ARGV.shift, "_http._tcp", "local" do |reply|
	p reply
end

trap 'INT' do resolver.stop; exit end
trap 'TERM' do resolver.stop; exit end

sleep

