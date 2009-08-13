require 'dnssd'

Thread.abort_on_exception = true

enumerator = DNSSD.enumerate_domains do |reply|
  p reply.domain
end

trap 'INT' do enumerator.stop; exit end
trap 'TERM' do enumerator.stop; exit end

sleep

