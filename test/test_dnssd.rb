require 'minitest/autorun'
require 'dnssd'
require 'socket'

class TestDNSSD < MiniTest::Unit::TestCase

  def setup
    @abort = Thread.abort_on_exception
    Thread.abort_on_exception = true

    @port = Socket.getservbyname 'blackjack'
  end

  def teardown
    Thread.abort_on_exception = @abort
  end

  def test_class_announce_tcp_server
    t = Thread.current
    DNSSD.browse '_blackjack._tcp' do |reply|
      next unless 'blackjack tcp server' == reply.name
      t[:reply] = reply
    end

    s = TCPServer.new 'localhost', @port

    DNSSD.announce s, 'blackjack tcp server'

    sleep 1

    assert_equal 'blackjack tcp server', t[:reply].name
  ensure
    s.close
  end

  def test_class_announce_tcp_server_service
    t = Thread.current

    DNSSD.resolve 'blackjack resolve', '_blackjack._tcp', 'local.' do |reply|
      t[:reply] = reply
    end

    s = TCPServer.new 'localhost', @port + 1

    DNSSD.announce s, 'blackjack resolve', 'blackjack'

    sleep 1

    assert_equal 'blackjack resolve', t[:reply].name
    assert_equal @port + 1, t[:reply].port
  ensure
    s.close
  end

  def test_class_getservbyport
    assert_equal 'blackjack', DNSSD.getservbyport(1025),
                 "Your /etc/services is out of date, sorry!"
  end

  def test_class_interface_index
    index = DNSSD.interface_index 'lo0'
    index = DNSSD.interface_index 'lo' if index.zero?
    refute_equal 0, index, 'what? no lo0? no lo?'
  end

  def test_class_interface_name
    index = DNSSD.interface_index 'lo0'
    index = DNSSD.interface_index 'lo' if index.zero?

    assert_match %r%^lo0?$%, DNSSD.interface_name(index)
  end

end

