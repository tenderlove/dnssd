require 'minitest/autorun'
require 'dnssd'

class TestDNSSDReply < MiniTest::Unit::TestCase

  def setup
    @reply = DNSSD::Reply.allocate # HACK
    @fullname = "Dr\\\.\032Pepper._http._tcp.local."
  end

  def test_fullname
    @reply.set_fullname @fullname

    assert_equal "Dr.\032Pepper._http._tcp.local.", @reply.fullname
  end

  def test_inspect
    flags = DNSSD::Flags.new
    @reply.instance_variable_set :@fullname,  'blah'
    @reply.instance_variable_set :@name,      'drbrain@pincer-tip'
    @reply.instance_variable_set :@interface, 'en2'
    @reply.instance_variable_set :@domain,    'local'
    @reply.instance_variable_set :@flags,     flags
    @reply.instance_variable_set :@type,      '_presence._tcp'

    expected = "#<DNSSD::Reply drbrain@pincer-tip type: _presence._tcp domain: local interface: en2 flags: #{flags}>"
    assert_equal expected, @reply.inspect
  end

  def test_set_fullname
    @reply.set_fullname @fullname

    assert_equal "Dr.\032Pepper", @reply.name
    assert_equal '_http._tcp', @reply.type
    assert_equal 'local.', @reply.domain
  end

end

