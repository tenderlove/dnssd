require 'dnssd'

Thread.abort_on_exception = true

domains = []

enumerator = DNSSD.enumerate_domains do |reply|
  domains << reply.domain
  next if reply.flags.more_coming?

  puts "Found domains:\n#{domains.join "\n"}"
  exit
end

trap 'INT' do enumerator.stop; exit end
trap 'TERM' do enumerator.stop; exit end

sleep

