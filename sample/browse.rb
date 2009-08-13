require 'dnssd'

services = []

browser = DNSSD.browse '_presence._tcp' do |reply|
  services << reply
  next if reply.flags.more_coming?

  puts "Presence services found:"
  services.each do |service|
    puts "#{service.name} on #{service.domain}"
  end

  exit
end

trap 'INT' do browser.stop; exit end
trap 'TERM' do browser.stop; exit end

sleep

