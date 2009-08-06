require 'dnssd'

service = DNSSD::Service.advertise_http "Chad's server", 8808 do |service|
  p service
  #service.name_changed? {|name| my_widget.update(name) }
end
sleep 4
service.stop

# collects the resolve results and trys each one (overlap)...when one
# succeeds, it cancels the other checks and returns.

browser = DNSSD::Browser.for_http do |service|
  host, port = service.resolve #optionally returns [host, port, iface]
end

sleep 4

browser.stop
if browser.more_coming?
  puts "blah"
end
browser.service_discovered? {|service|}
browser.service_lost? {|service|}
browser.on_changed do
  # get current values for UI update
end
browser.all_current #=> [service1, service2]
browser.changed? 

