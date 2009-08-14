require 'dnssd'

Thread.abort_on_exception = true

DNSSD.register "hey ruby", "_http._tcp", nil, 8081

registrar = DNSSD.register "chad ruby", "_http._tcp", nil, 8080 do |reply|
  p :registered => reply.fullname
end

sleep 1

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

sleep 0.1

browser.stop
registrar.stop

