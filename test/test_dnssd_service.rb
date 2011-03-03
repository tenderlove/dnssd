require 'minitest/autorun'
require 'dnssd'

class TestDNSSDService < MiniTest::Unit::TestCase

  def test_class_get_property
    skip 'DNSSD::Service::get_property not defined' unless
      DNSSD::Service.respond_to? :get_property

    assert_kind_of Numeric,
                   DNSSD::Service.get_property(DNSSD::Service::DaemonVersion)
  end

  def test_class_getaddrinfo
    service = DNSSD::Service.new

    addresses = []

    service.getaddrinfo 'localhost' do |addrinfo|
      addresses << addrinfo.address
      break unless addrinfo.flags.more_coming?
    end

    assert addresses.index('127.0.0.1')
  end

end

