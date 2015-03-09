require 'helper'

class TestDNSSD < DNSSD::Test
  def setup
    @abort = Thread.abort_on_exception
    Thread.abort_on_exception = true

    @port = Socket.getservbyname 'blackjack'
  end

  def teardown
    Thread.abort_on_exception = @abort
  end

  def test_class_announce_tcp_server
    t = nil
    latch = Latch.new

    browse = DNSSD.browse '_blackjack._tcp' do |reply|
      next unless 'blackjack tcp server' == reply.name
      t = reply
      latch.release
    end

    s = TCPServer.new 'localhost', @port

    DNSSD.announce s, 'blackjack tcp server'

    latch.await

    assert_equal 'blackjack tcp server', t.name
  ensure
    browse.stop
    s.close
  end

  def test_class_announce_tcp_server_service
    t = nil
    latch = Latch.new

    rs = DNSSD.resolve 'blackjack resolve', '_blackjack._tcp', 'local.' do |reply|
      t = reply
      latch.release
    end

    s = TCPServer.new 'localhost', @port + 1

    DNSSD.announce s, 'blackjack resolve', 'blackjack'

    latch.await

    assert_equal 'blackjack resolve', t.name
    assert_equal @port + 1, t.port
  ensure
    rs.stop
    s.close if s
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
