require 'dnssd'

Thread.abort_on_exception = true
trap 'INT' do exit end
trap 'TERM' do exit end

query = DNSSD::Service.new

abort "#{$0} fullname" if ARGV.empty?
fullname = ARGV.shift

query.query_record fullname, DNSSD::Record::SRV do |record|
  puts record
end

