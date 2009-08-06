require 'dnssd'

#blockless_registrar = DNSSD.register "hey ruby", "_http._tcp", nil, 8081

registrar = DNSSD.register "chad ruby", "_http._tcp", nil, 8080 do |reply|
  p :registered => reply
end

sleep 1

browser = DNSSD.browse '_http._tcp' do |reply|
  p :browsed => reply
end

sleep 1

browser.stop
#blockless_registrar.stop
registrar.stop

