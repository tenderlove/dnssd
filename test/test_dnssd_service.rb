require 'helper'

class TestDNSSDService < DNSSD::Test

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

  def test_register_browse
    registered = Latch.new
    found      = Latch.new
    name       = SecureRandom.hex

    domains = []
    broadcast = Thread.new do
      service = DNSSD::Service.register name, "_http._tcp", nil, 8080
      service.each_response do |r|
        domains << r.domain
        registered.release
        found.await
        service.stop
      end
    end

    find = Thread.new do
      service = DNSSD::Service.browse '_http._tcp'
      service.each_response do |r|
        if r.name == name
          found.release
          service.stop
          assert_equal name, r.name
          assert_equal "_http._tcp", r.type
          assert_includes domains, r.domain
        end
      end
    end

    found.await
    broadcast.join
    find.join
  end
end
