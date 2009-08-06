require 'minitest/autorun'
require 'dnssd'

class TestDNSSDTextRecord < MiniTest::Unit::TestCase

  def test_text_record
    tr = DNSSD::TextRecord.new
    tr["key"]="value"
    enc_str = ["key", "value"].join('=')
    enc_str = enc_str.length.chr << enc_str
    assert_equal(enc_str, tr.encode)

    # should raise type error
    assert_raises TypeError do
      DNSSD::TextRecord.decode :HEY
    end

    tr_new = DNSSD::TextRecord.decode enc_str

    assert_equal tr_new, tr

    # new called with just a string should be the same as decode.

    tr_new = DNSSD::TextRecord.new enc_str
    assert_equal tr_new, tr
  end

  def test_decode_empty
    # text records with N 0-length entries
    DNSSD::TextRecord.new("")
    DNSSD::TextRecord.new("\x00")
    DNSSD::TextRecord.new("\x00\x00")

    # 0-length string, key-value string
    DNSSD::TextRecord.new("\x00\x01k")
    DNSSD::TextRecord.new("\x00\x02k=")
    DNSSD::TextRecord.new("\x00\x03k=v")

    assert_raises ArgumentError do
      # length past end-of-record
      DNSSD::TextRecord.new("\x00\x01")
    end

    assert_raises ArgumentError do
      # 0-length string, no key
      DNSSD::TextRecord.new("\x00\x01=")
    end

    assert_raises ArgumentError do
      # 0-length string, no key
      DNSSD::TextRecord.new("\x00\x02=v")
    end
  end

end

