require 'dnssd'

browser = DNSSD.browse '_presence._tcp' do |reply|
  p reply
end

trap 'INT' do browser.stop; exit end
trap 'TERM' do browser.stop; exit end

sleep

