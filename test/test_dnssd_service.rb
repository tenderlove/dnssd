require 'minitest/autorun'
require 'dnssd'

class TestDNSSDService < MiniTest::Unit::TestCase

  def test_class_get_property
    assert_kind_of Numeric,
                   DNSSD::Service.get_property(DNSSD::Service::DaemonVersion)
  end if DNSSD::Service.respond_to? :get_property

end

