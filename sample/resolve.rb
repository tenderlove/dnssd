require 'dnssd'

Thread.abort_on_exception = true
trap 'INT' do exit end
trap 'TERM' do exit end

puts "Resolving TCP blackjack services"
puts "(run sample/register.rb)"
puts

browser = DNSSD::Service.new
services = {}

browser.browse '_blackjack._tcp' do |reply|
  services[reply.fullname] = reply
  next if reply.flags.more_coming?

  services.sort_by do |_, service|
    [(service.flags.add? ? 0 : 1), service.fullname]
  end.each do |_, service|
    next unless service.flags.add?

    DNSSD::Service.new.resolve service do |r|
      puts "#{r.name} on #{r.target}:#{r.port}"
      puts "\t#{r.text_record.inspect}" unless r.text_record.empty?
      break unless r.flags.more_coming?
    end
  end

  services.clear

  puts
end

