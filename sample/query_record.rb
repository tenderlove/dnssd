require 'dnssd'

Thread.abort_on_exception = true
trap 'INT' do exit end
trap 'TERM' do exit end

abort "#{$0} fullname" if ARGV.empty?
fullname = ARGV.shift

DNSSD::Service.query_record fullname, DNSSD::Record::SRV do |record|
  puts record
end

