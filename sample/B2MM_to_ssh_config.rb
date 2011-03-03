require 'dnssd'

domains = []

service = DNSSD::Service.new

service.enumerate_domains do |reply|
  domains << reply.domain
  break unless reply.flags.more_coming?
end

domain = domains.grep(/\.members\.mac\.com\.$/).first

abort "Is Back To My Mac enabled?  A members.mac.com domain wasn't found" unless
  domain

names = []

service = DNSSD::Service.new

service.browse '_ssh._tcp', domain do |reply|
  names << reply
  break unless reply.flags.more_coming?
end

hosts = []

names.each do |name|
  service = DNSSD::Service.new

  service.resolve name do |reply|
    hosts << [reply.name, reply.target]
    break
  end
end

hosts.each do |host, hostname|
  puts "Host #{host}"
  puts "  Hostname #{hostname}"
  puts
end

