require 'minitest/autorun'
require 'dnssd'

class TestDNSSDReplyQueryRecord < MiniTest::Unit::TestCase

  def setup
    @fullname = 'blackjack._blackjack._tcp.test.'
    @IN = DNSSD::Record::IN
    @ipv4 = "\300\000\002\001"
    @ipv6 = " \001\r\270\000\000\000\000\000\000\000\000\000\000\000\001"
    @nowhere = "\007nowhere\007example\000"
  end

  def test_record_data_A
    qr = util_qr DNSSD::Record::A, @ipv4

    assert_equal IPAddr.new_ntoh(@ipv4), qr.record_data
  end

  def test_record_data_AAAA
    qr = util_qr DNSSD::Record::A, @ipv6

    assert_equal IPAddr.new_ntoh(@ipv6), qr.record_data
  end

  def test_record_data_CNAME
    qr = util_qr DNSSD::Record::CNAME, @nowhere

    assert_equal 'nowhere.example.', qr.record_data
  end

  def test_record_data_MX
    qr = util_qr DNSSD::Record::MX, "\000\010#{@nowhere}"

    assert_equal [8, 'nowhere.example.'], qr.record_data
  end

  def test_record_data_NS
    qr = util_qr DNSSD::Record::NS, @nowhere

    assert_equal 'nowhere.example.', qr.record_data
  end

  def test_record_data_PTR
    qr = util_qr DNSSD::Record::PTR, @nowhere

    assert_equal 'nowhere.example.', qr.record_data
  end

  def test_record_data_SOA
    serial = 1
    refresh = 86400
    rtry = 3600
    expire = 86400 * 2
    minimum = 3600 * 12

    data = "#{@nowhere}\002me#{@nowhere}#{[serial, refresh, rtry, expire, minimum].pack 'NNNNN'}"

    qr = util_qr DNSSD::Record::SOA, data

    expected = [
      'nowhere.example.', 'me.nowhere.example.',
      serial, refresh, rtry, expire, minimum
    ]

    assert_equal expected, qr.record_data
  end

  def test_record_data_SRV
    priority = 1
    weight = 5
    port = 1025

    data = "#{[priority, weight, port].pack 'nnn'}#{@nowhere}"

    qr = util_qr DNSSD::Record::SRV, data

    assert_equal [1, 5, 1025, 'nowhere.example.'], qr.record_data
  end

  def test_record_data_TXT
    qr = util_qr DNSSD::Record::TXT, "\005Hello\006World!"

    assert_equal %w[Hello World!], qr.record_data
  end

  def util_qr(rtype, rdata)
    DNSSD::Reply::QueryRecord.new nil, 0, 0, @fullname, rtype, @IN, rdata, 120
  end

end

