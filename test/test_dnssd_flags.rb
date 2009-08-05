require 'minitest/autorun'
require 'dnssd'

class TestDNSSDFlags < MiniTest::Unit::TestCase

  def setup
    @flags = DNSSD::Flags.new
  end

  def test_inspect
    assert_equal '#<DNSSD::Flags>', @flags.inspect

    @flags.add = true
    @flags.default = true

    assert_equal '#<DNSSD::Flags add, default>', @flags.inspect
  end

end

