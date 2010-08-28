require 'minitest/autorun'
require 'dnssd'

class TestDNSSDTextRecord < MiniTest::Unit::TestCase
  TR = DNSSD::TextRecord

  def test_encode
    tr = TR.new

    tr['key1'] = nil
    tr['key2'] = ''
    tr['key3'] = 'value'

    assert_equal "\004key1\005key2=\012key3=value", tr.encode
  end

  def test_encode_long
    tr = TR.new

    tr['key'] = 'X' * 252

    e = assert_raises DNSSD::Error do
      tr.encode
    end

    assert_equal 'key value pair at \'key\' too large to encode', e.message
  end

  def test_decode
    text_record = "\fstatus=avail\006email=\004jid=\005node=\tversion=1\ttxtvers=1\016port.p2pj=5298\0161st=Eric Hodel\005nick=\004AIM=\005last=-phsh=59272d0c3ed947b4660fabc0dad9d67647507299\004ext="

    expected = {
      'status'    => 'avail',
      'ext'       => '',
      'node'      => '',
      'nick'      => '',
      'last'      => '',
      'txtvers'   => '1',
      'AIM'       => '',
      'jid'       => '',
      'phsh'      => '59272d0c3ed947b4660fabc0dad9d67647507299',
      'version'   => '1',
      '1st'       => 'Eric Hodel',
      'port.p2pj' => '5298',
      'email'     => ''
    }

    assert_equal expected, TR.new(text_record).to_hash
  end

  def test_decode_bad
    assert_raises ArgumentError do
      TR.new("\x01") # length past end-of-record
    end

    assert_raises ArgumentError do
      # no key
      TR.new("\x01=")
    end

    assert_raises ArgumentError do
      # 0-length key
      TR.new("\x02=v")
    end
  end

  def test_decode_empty
    assert_equal({}, TR.new(""))
    assert_equal({}, TR.new("\x00"))
    assert_equal({}, TR.new("\x00\x00"))
  end

  def test_decode_value
    assert_equal({ 'k' => nil }, TR.new("\x01k").to_hash)
    assert_equal({ 'k' => ''  }, TR.new("\x02k=").to_hash)
    assert_equal({ 'k' => 'v' }, TR.new("\x03k=v").to_hash)
  end

end

