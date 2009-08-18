require 'minitest/autorun'
require 'dnssd'

class TestDNSSDRecord < MiniTest::Unit::TestCase

  def setup
    @fullname = 'blackjack._blackjack._tcp.test.'
    @IN = DNSSD::Record::IN
    @ipv4 = "\300\000\002\001"
    @ipv6 = " \001\r\270\000\000\000\000\000\000\000\000\000\000\000\001"
    @nowhere = "\007nowhere\007example\000"

    @R = DNSSD::Record
  end

  def test_class_to_data_invalid
    assert_raises ArgumentError do
      @R.to_data(-1)
    end
  end

  def test_class_to_data_A
    assert_equal @ipv4, @R.to_data(DNSSD::Record::A, '192.0.2.1')
    assert_equal @ipv4, @R.to_data(DNSSD::Record::A, IPAddr.new('192.0.2.1'))

    assert_raises ArgumentError do
      @R.to_data DNSSD::Record::A, '2001:db8::1'
    end
  end

  def test_class_to_data_AAAA
    assert_equal @ipv6, @R.to_data(DNSSD::Record::AAAA, '2001:db8::1')
    assert_equal @ipv6,
                 @R.to_data(DNSSD::Record::AAAA, IPAddr.new('2001:db8::1'))

    assert_raises ArgumentError do
      @R.to_data DNSSD::Record::AAAA, '192.0.2.1'
    end
  end

  def test_class_to_data_CNAME
    assert_equal @nowhere, @R.to_data(DNSSD::Record::CNAME, 'nowhere.example.')
  end

  def test_class_to_data_MX
    assert_equal "\000\010#{@nowhere}",
                 @R.to_data(DNSSD::Record::MX, 8, 'nowhere.example.')
  end

  def test_class_to_data_NS
    assert_equal @nowhere, @R.to_data(DNSSD::Record::NS, 'nowhere.example.')
  end

  def test_class_to_data_PTR
    assert_equal @nowhere, @R.to_data(DNSSD::Record::PTR, 'nowhere.example.')
  end

  def test_class_to_data_SOA
    serial = 1
    refresh = 86400
    rtry = 3600
    expire = 86400 * 2
    minimum = 3600 * 12

    expected = "#{@nowhere}\002me#{@nowhere}#{[serial, refresh, rtry, expire, minimum].pack 'NNNNN'}"

    data = @R.to_data(DNSSD::Record::SOA, 'nowhere.example.',
                      'me.nowhere.example.', serial, refresh, rtry, expire,
                      minimum)

    assert_equal expected, data
  end

  def test_class_to_data_SRV
    priority = 1
    weight = 5
    port = 1025

    expected = "#{[priority, weight, port].pack 'nnn'}#{@nowhere}"

    assert_equal expected,
                 @R.to_data(DNSSD::Record::SRV, priority, weight, port,
                            'nowhere.example.')
  end

  def test_class_to_data_TXT
    assert_equal "\005Hello\006World!",
                 @R.to_data(DNSSD::Record::TXT, 'Hello', 'World!')
  end

end

