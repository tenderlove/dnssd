require 'minitest/autorun'
require 'dnssd'

class TestDNSSDReply < MiniTest::Unit::TestCase

  def setup
    @reply = DNSSD::Reply.new nil, 0, 0
    @fullname = "Eric\\032Hodel._http._tcp.local."
  end

  def test_fullname
    @reply.set_fullname @fullname

    assert_equal "Eric\\032Hodel._http._tcp.local.", @reply.fullname

    @reply.instance_variable_set :@name, 'Dr. Pepper'

    assert_equal "Dr\\.\\032Pepper._http._tcp.local.", @reply.fullname
  end

  def test_inspect
    flags = DNSSD::Flags.new DNSSD::Flags::MoreComing
    @reply.instance_variable_set :@interface, 'lo0'
    @reply.instance_variable_set :@flags,     flags

    expected = "#<DNSSD::Reply:0x#{@reply.object_id.to_s 16} interface: lo0 flags: #{flags.inspect}>"
    assert_equal expected, @reply.inspect
  end

  def test_protocol
    @reply.set_fullname @fullname

    assert_equal 'tcp', @reply.protocol
  end

  def test_service_name
    @reply.set_fullname @fullname

    assert_equal 'http', @reply.service_name
  end

  def test_set_fullname
    @reply.set_fullname @fullname

    assert_equal "Eric Hodel", @reply.instance_variable_get(:@name)
    assert_equal '_http._tcp',    @reply.instance_variable_get(:@type)
    assert_equal 'local.',        @reply.instance_variable_get(:@domain)

    @reply.set_fullname "Dr\\.\\032Pepper._http._tcp.local."

    assert_equal "Dr. Pepper", @reply.instance_variable_get(:@name)
    assert_equal '_http._tcp',    @reply.instance_variable_get(:@type)
    assert_equal 'local.',        @reply.instance_variable_get(:@domain)

    @reply.set_fullname "Dr\\.\\032Pepper\\032\\0352._http._tcp.local."
    assert_equal "Dr. Pepper #2", @reply.instance_variable_get(:@name)
  end

  def test_set_names
    @reply.set_names "Dr\\.\032Pepper", '_http._tcp', 'local.'

    assert_equal "Dr.\032Pepper", @reply.instance_variable_get(:@name)
    assert_equal '_http._tcp',    @reply.instance_variable_get(:@type)
    assert_equal 'local.',        @reply.instance_variable_get(:@domain)
  end

end

