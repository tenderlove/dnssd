require 'helper'

class TestDNSSD < DNSSD::Test
  def setup
    @abort = Thread.abort_on_exception
    Thread.abort_on_exception = true

    begin
      @port = Socket.getservbyname 'blackjack'
    rescue
      @port = 1025
    end
  end

  def teardown
    Thread.abort_on_exception = @abort
  end

  def test_synchronous_register
    reply = DNSSD.register! name, "_http._tcp", nil, 8080 do |r|
      break r
    end
    assert reply
  end

  def test_synchronous_enumerate
    Timeout.timeout(2, Minitest::Skip) do
      reply = DNSSD.enumerate_domains! do |r|
        break r
      end
      assert reply
    end
  end

  def test_asynchronous_enumerate
    latch = Latch.new
    reply = DNSSD.enumerate_domains do |r|
      latch.await
    end
    latch.release
    assert reply
  end

  def test_synchronous_browse
    register = DNSSD::Service.register name, "_http._tcp", nil, 8080
    thing = nil
    DNSSD.browse!('_http._tcp') do |r|
      thing = true
      break
    end
    assert thing
    register.stop
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

    stub Socket, :getservbyport, 'blackjack' do
      DNSSD.announce s, 'blackjack tcp server'
    end

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
