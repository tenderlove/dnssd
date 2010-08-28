require 'minitest/autorun'
require 'dnssd'
require 'socket'

class TestDNSSD < MiniTest::Unit::TestCase

  def test_getaddrinfo
    service = DNSSD::Service.new

    addresses = []
    begin
      service.getaddrinfo 'localhost' do |addrinfo|
        addresses << addrinfo.address
        break unless addrinfo.flags.more_coming?
      end
    ensure
      service.stop
    end
    assert addresses.index('127.0.0.1')
  end

end

