require 'helper'

class TestDNSSDService < DNSSD::Test

  def test_class_get_property
    skip 'DNSSD::Service::get_property not defined' unless
      DNSSD::Service.respond_to? :get_property

    assert_kind_of Numeric,
                   DNSSD::Service.get_property(DNSSD::Service::DaemonVersion)
  end

  def test_class_getaddrinfo
    addresses = []
    service = DNSSD::Service.getaddrinfo 'localhost'

    service.each_reply do |addrinfo|
      addresses << addrinfo.address
      break unless addrinfo.flags.more_coming?
    end

    assert addresses.index('127.0.0.1')
  end

  def test_enumerate
    service = DNSSD::Service.enumerate_domains
    service.each_reply do |reply|
      # I *think* there will be a local. on every machine??
      break if reply.domain == 'local.'
    end
    assert true
  end

  Thread.abort_on_exception = true
  def test_register_browse
    registered = Latch.new
    found      = Latch.new
    name       = SecureRandom.hex

    broadcast = Thread.new do
      service = DNSSD::Service.register name, "_http._tcp", nil, 8080
      service.each_reply do |reply|
        if reply.domain == "local."
          registered.release
          found.await
          service.stop
        end
      end
    end

    find = Thread.new do
      registered.await
      service = DNSSD::Service.browse '_http._tcp'
      service.each_reply do |r|
        if r.name == name && r.domain == "local."
          found.release
          service.stop
          assert_equal name, r.name
          assert_equal "_http._tcp", r.type
        end
      end
    end

    found.await
    broadcast.join
    find.join
  end
end
