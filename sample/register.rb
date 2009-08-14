require 'dnssd'

Thread.abort_on_exception = true

#DNSSD.register 'blockless', '_http._tcp', nil, 8081
#DNSSD.register 'block', '_http._tcp', nil, 8081 do |r| end

registrar = DNSSD::Service.new

service = nil

tr = DNSSD::TextRecord.new
tr['foo'] = 'bar'
registrar.register 'add_record', '_http._tcp', nil, 8080, nil, tr
registrar.add_record DNSSD::Record::RP, 'nobody.local. .'

sleep 2

puts

found = {}

browser = DNSSD.browse '_http._tcp' do |reply|
  if reply.flags.more_coming? then
    found[reply.name] = true
  else
    puts "found:\n#{found.keys.join "\n"}"
    puts

    found.clear
  end
end

sleep #0.1

browser.stop
registrar.stop

