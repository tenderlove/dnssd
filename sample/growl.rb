require 'dnssd'

Thread.abort_on_exception = true

browser = DNSSD.browse '_growl._tcp' do |b|
  DNSSD.resolve b.name, b.type, b.domain do |r|
    puts "#{b.name} of #{b.type} in #{b.domain} => #{r.target}:#{r.port} on #{b.interface} txt #{r.text_record.inspect}"
    break
  end
end

trap 'INT' do browser.stop; exit end
trap 'TERM' do browser.stop; exit end

sleep

