require 'minitest/autorun'
require 'dnssd'

class TestDNSSD < MiniTest::Unit::TestCase

  def test_class_getservbyport
    assert_equal 'http', DNSSD.getservbyport(80)
  end

end

